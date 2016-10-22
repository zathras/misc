/**
 * Simple HTTP server, using code swiped from simples, whic was swiped from hat.
 * This has been hacked to be a voting server.
 *
 * @author Bill Foote
 */

import java.net.InetAddress
import java.security.SecureRandom

import server.ErrorQueryHandler
import server.QueryHandler
import server.QueryListener
import java.io.*
import java.net.NetworkInterface
import java.net.Inet4Address;
import java.util.*
import java.util.concurrent.locks.Condition
import java.util.concurrent.locks.Lock
import kotlin.concurrent.withLock

public val localInetAddress = getAddress()

private fun getAddress() : InetAddress {
    for (ne in NetworkInterface.getNetworkInterfaces()) {
        for (ie in ne.getInetAddresses()) {
            if (!ie.isLoopbackAddress() && ie is Inet4Address) {
                return ie;
            }
        }
    }
    for (ne in NetworkInterface.getNetworkInterfaces()) {
        for (ie in ne.getInetAddresses()) {
            if (!ie.isLoopbackAddress()) {
                return ie;
            }
        }
    }
    return InetAddress.getLocalHost()
}

class SimpleHttp(
        val ballot : Ballot,
        val lock : Lock,
        val voteReceived : Condition) : QueryListener(6001, false)
{
    override fun getHandler(query: String, rawOut: OutputStream, out: PrintWriter,
                            user : InetAddress): QueryHandler?
    {
        return BallotQuery(ballot, rawOut, out, user, lock)
    }

    override fun handlePost(headers: HashMap<String, String>, input: BufferedInputStream,
                            rawOut: OutputStream, out: PrintWriter,
                            user : InetAddress) : QueryHandler?
    {
        var remaining = headers["Content-Length"]?.toLong()
        val contentType = headers["Content-Type"]
        if (remaining == null) {
            println("POST error:  No content length")
            return null;
        }
        if (contentType != "text/plain") {
            println("POST warning:  contentType is $contentType, not text/plain.")
            println("I'll process it, but you get what you get.")
        }
        var found : Long? = null
        var round : Int? = null
        var timestamp : Long? = null
        val votes = mutableSetOf<Int>()
        while (remaining > 0) {
            val ch = input.read();
            if (ch in '0'.toInt() .. '9'.toInt()) {
                val d = ch - '0'.toInt()
                found = if (found == null)  d.toLong() else  found * 10 + d
            } else if (ch == '='.toInt()) {
                if (found == null) {
                    println("parse error:  found is null")
                } else {
                    if (found >= 0) {   // If this isn't -1 from below
                        votes.add(found.toInt())
                    }
                    found = null
                }
            } else if (ch == 't'.toInt()) {
                if (found == null) {
                    println("parse error:  found is null for timestamp")
                } else {
                    timestamp = found
                    found = -1      // Skip error when we see the '='
                }
            } else if (ch == 'r'.toInt()) {
                if (found == null) {
                    println("parse error:  found is null for round")
                } else {
                    round = found.toInt()
                    found = -1      // Skip error when we see the '='
                }
            } else if (found != null) {
                println("""parse error:  no "=" after number""")
                found = null;
            }
            remaining--;
        }
        lock.withLock {
            if (ballot.timestamp != timestamp) {
                println("Error:  $user tried to vote on a different (older?) ballot.")
            } else if (ballot.round != round) {
                println("Error:  $user tried to vote in round $round.")
            } else if (ballot.voted.contains(user)) {
                println("Error:  $user tried to vote twice.")
            } else {
                for (i in votes) {
                    ballot.candidates[i].votes++
                }
                ballot.voted.add(user)
                voteReceived.signalAll()
            }
        }
        return BallotQuery(ballot, rawOut, out, user, lock)
    }

    val publicURL: String @Throws(IOException::class)
        get() {
            val scheme = if (enableSsl) "https" else "http"
            return scheme + "://" + localInetAddress.hostAddress + ":" + port + "/"
        }
}

