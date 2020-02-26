
import kotlinx.coroutines.*
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.AsynchronousServerSocketChannel
import java.nio.channels.AsynchronousSocketChannel
import java.nio.channels.CompletionHandler
import java.util.concurrent.CompletableFuture
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Implements a server on port 7777 that reverses each line it gets.
 * The server uses one thread, but can service multiple clients
 * simultaneously.  It uses the nio classes and Kotlin coroutines.
 * This is intended to play around with coroutines, and figure out how
 * to link them to a real asynchronous Java library.
 *
 * It's interesting to note that even with coroutines, the buffer management
 * makes this code relatively painful.
 */
object UsingCoroutines {

    fun run() = runBlocking {
        println("Started")
        val ssChannel = AsynchronousServerSocketChannel.open()
        ssChannel.bind(InetSocketAddress(7777))
        while (true) {
            val channel : AsynchronousSocketChannel = suspending { ssChannel.accept(null, it) }
            val output = OutputAdapter(channel, 5)
            val input = InputAdapter(channel, 4)
            println(channel)
            async {
                val line = StringBuffer()
                while (true) {
                    val chi = input.getchar()
                    if (chi == -1) {
                        break
                    }
                    val ch = chi.toChar()
                    println("Read $ch")
                    line.append(ch)
                    if (ch == '\r' || ch == '\n') {
                        writeReversed(line, output)
                    }
                }
                println("Done with $channel")
            }
        }
    }

    suspend fun writeReversed(line: StringBuffer, writer: OutputAdapter) {
        while (line.isNotEmpty()) {
            val i = if (line.length == 1) 0 else line.lastIndex - 1
            val ch = line.get(i)        // avoid EOLN until end
            line.deleteCharAt(i)
            println("writing $ch")
            writer.write(ch.toByte())
        }
        writer.flush()
    }
}

class InputAdapter(val channel: AsynchronousSocketChannel, bufferSize: Int) {
    private val buffer = ByteBuffer.allocate(bufferSize)

    init {
        buffer.flip()
    }

    suspend fun getchar() : Int {
        if (!buffer.hasRemaining()) {
            buffer.clear()
            val bytesRead: Int = suspending { channel.read(buffer, null, it) }
            buffer.flip()
            if (bytesRead == -1) {
                return -1
            }
        }
        return buffer.get().toInt()
    }
}

class OutputAdapter(val channel: AsynchronousSocketChannel, bufferSize: Int) {
    private val buffer = ByteBuffer.allocate(bufferSize)

    suspend fun write(b: Byte) {
        if (!buffer.hasRemaining()) {
            flush()
        }
        buffer.put(b)
    }

    suspend fun flush() {
        buffer.flip()
        while (buffer.hasRemaining()) {
            val result : Int = suspending { channel.write(buffer, null, it) }
            if (result == -1) {
                channel.close()
                break
            }
        }
        buffer.clear()
    }
}


/*******************************************************************
 * Some glue between futures and coroutines.  I'm sure more
 * generic versions of these exist in a standard library somewhere.
 *******************************************************************/

suspend fun<R> suspending(body: (h: CompletionHandler<R?, Unit?>) -> Unit) : R {
    val result = CompletableFuture<R>()
    body(object: CompletionHandler<R?, Unit?> {
        override fun completed(ch: R?, p1: Unit?) {
            if (ch == null) {
                result.completeExceptionally(NullPointerException())
            } else {
                result.complete(ch)
            }
        }

        override fun failed(t: Throwable?, ignored : Unit?) {
            if (t == null) {
                result.completeExceptionally(NullPointerException())
            } else {
                result.completeExceptionally(t)
            }
        }

    })
    return result.await()
}

suspend fun <T> CompletableFuture<T>.await(): T =
    suspendCoroutine<T> { cont: Continuation<T> ->
        whenComplete { result, exception ->
            if (exception == null) // the future has been completed normally
                cont.resume(result)
            else // the future has completed with an exception
                cont.resumeWithException(exception)
        }
    }

