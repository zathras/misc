
import kotlinx.coroutines.*
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.AsynchronousServerSocketChannel
import java.nio.channels.AsynchronousSocketChannel
import java.nio.channels.CompletionHandler
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Future
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
            val readBuffer = ByteBuffer.allocate(4)
            val writeBuffer = ByteBuffer.allocate(5)
            println(channel)
            async {
                val line = StringBuffer()
                while (true) {
                    val bytesRead: Int = suspending { channel.read(readBuffer, null, it) }
                    if (bytesRead == -1) {
                        break
                    }
                    readBuffer.flip()
                    while (readBuffer.hasRemaining()) {
                        val ch = readBuffer.get().toChar()
                        println("Read $ch")
                        line.append(ch)
                        if (ch == '\r' || ch == '\n') {
                            writeReversed(line, writeBuffer, channel)
                        }
                    }
                    readBuffer.clear()
                }
            }
        }
    }

    suspend fun writeReversed(line: StringBuffer, writeBuffer: ByteBuffer, channel: AsynchronousSocketChannel) {
        while (line.isNotEmpty()) {
            while (line.isNotEmpty() && writeBuffer.hasRemaining()) {
                val i = if (line.length == 1) 0 else line.lastIndex - 1
                val ch = line.get(i)        // avoid EOLN until end
                line.deleteCharAt(i)
                println("writing $ch")
                writeBuffer.put(ch.toByte())
            }
            writeBuffer.flip()
            while (writeBuffer.hasRemaining()) {
                val result : Int = suspending { channel.write(writeBuffer, null, it) }
                if (result == -1) {
                    channel.close()
                    break
                }
                if (!writeBuffer.hasRemaining()) {
                    break
                }
            }
            writeBuffer.clear()
        }
    }
}

/**
 * I"m sure this exists in a standard library somewhere
 */
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

/**
 * I"m sure this exists in a standard library somewhere
 */
suspend fun <T> CompletableFuture<T>.await(): T =
    suspendCoroutine<T> { cont: Continuation<T> ->
        whenComplete { result, exception ->
            if (exception == null) // the future has been completed normally
                cont.resume(result)
            else // the future has completed with an exception
                cont.resumeWithException(exception)
        }
    }

