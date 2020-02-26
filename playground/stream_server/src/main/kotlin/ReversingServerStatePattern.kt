
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.SelectionKey
import java.nio.channels.Selector
import java.nio.channels.ServerSocketChannel
import java.nio.channels.SocketChannel

/**
 * Implements a server on port 7777 that reverses each line it gets.
 * The server uses one thread, but can service multiple clients
 * simultaneously.  It uses the "raw" nio classes and the state pattern.
 * This is intended to illustrate what coroutines (and futures)
 * conceptually do "under the hood."
 */
object ReversingServerStatePattern {

    class Reverser : () -> Unit
    {
        private var state : State
        private val readBuffer: ByteBuffer
        private val writeBuffer: ByteBuffer
        private val line = StringBuffer()
        private val selector : Selector
        private val socket : SocketChannel


        constructor(selector: Selector, socket: SocketChannel) {
            this.selector = selector
            socket.configureBlocking(false)
            readBuffer = ByteBuffer.allocate(4)
            writeBuffer = ByteBuffer.allocate(5)
            this.socket = socket
            this.state = READING
        }

        fun start() = state.register(this)

        interface State : (Reverser) -> Unit {
            fun running() : Boolean
            fun register(reverser: Reverser)
        }

        companion object {

            val READING : State = object : State {
                override fun running() = false
                override fun register(reverser: Reverser) {
                    reverser.socket.register(reverser.selector, SelectionKey.OP_READ, reverser)
                }

                override fun invoke(reverser: Reverser) {
                    with(reverser) {
                        assert(readBuffer.hasRemaining())
                        val result = socket.read(readBuffer)
                        if (result == -1) {
                            // Discard any pending buffered output
                            socket.close()
                            state = CLOSED
                            return
                        }
                        readBuffer.flip()
                        state = PROCESSING_READ
                    }
                }
            }

            val PROCESSING_READ : State = object : State {
                override fun running() = true
                override fun register(reverser: Reverser) {
                }

                override fun invoke(reverser: Reverser) {
                    with(reverser) {
                        while (readBuffer.hasRemaining()) {
                            val ch = readBuffer.get().toChar()
                            line.append(ch)
                            println("Received $ch")
                            if (ch == '\r' || ch == '\n') {
                                state = PROCESSING_WRITE
                                return
                            }
                        }
                        readBuffer.clear()
                        state = READING

                    }
                }
            }


            val PROCESSING_WRITE : State = object : State {
                override fun running() = true
                override fun register(reverser: Reverser) {
                }

                override fun invoke(reverser: Reverser) {
                    with (reverser) {
                        if (line.isEmpty()) {
                            state = PROCESSING_READ   // In case read buffer has more
                            return
                        }
                        while (!line.isEmpty() && writeBuffer.hasRemaining()) {
                            val i = if (line.length == 1) 0 else line.lastIndex - 1
                            val ch = line.get(i)        // avoid EOLN until end
                            line.deleteCharAt(i)
                            println("writing $ch")
                            writeBuffer.put(ch.toByte())
                        }
                        writeBuffer.flip()
                        state = WRITING
                        return
                    }
                }
            }

            val WRITING : State = object : State {
                override fun running() = false
                override fun register(reverser: Reverser) {
                    reverser.socket.register(reverser.selector, SelectionKey.OP_WRITE, reverser)
                }

                override fun invoke(reverser: Reverser) {
                    with (reverser) {
                        val result = socket.write(writeBuffer)
                        if (result == -1) {
                            socket.close()
                            state = CLOSED
                            return
                        }
                        if (!writeBuffer.hasRemaining()) {
                            writeBuffer.clear()
                            state = PROCESSING_WRITE
                        }

                    }
                }
            }

            val CLOSED : State = object : State {
                override fun running() = false
                override fun register(reverser: Reverser) = Unit
                override fun invoke(reverser: Reverser) = Unit
            }
        }

        override fun invoke() {
            try {
                do {
                    state(this)
                } while (state.running())
                state.register(this)
            } catch (ex : Exception) {
                ex.printStackTrace()
                socket.close()
            }
        }
    }

    val selector = Selector.open()

    private fun acceptConnection(ssChannel: ServerSocketChannel) {
        val socket: SocketChannel = ssChannel.accept()
        println("Accepted $socket")
        val r = Reverser(selector, socket)
        r.start()
    }

    fun run() {
        val ssChannel = ServerSocketChannel.open()
        ssChannel.configureBlocking(false)
        ssChannel.bind(InetSocketAddress(7777))
        val ssKey = ssChannel.register(selector, SelectionKey.OP_ACCEPT, {
            acceptConnection(ssChannel)
        })
        while (true) {
            println("Selecting from ${selector.keys()}...")
            selector.select()
            println("Selected.")
            val selected = selector.selectedKeys()
            for (key in selector.selectedKeys()) {
                println(key == ssKey)
                @Suppress("UNCHECKED_CAST")
                val task = key.attachment() as () -> Unit
                task()
            }
            selected.clear()
        }
    }
}
