/**
 * Simple HTTP server, using code swiped from hat.
 * <p>
 *
 * Starts an http server on port 6001 in the cwd.  As a security measure,
 * the base URL for all files is http:///.  It screens
 * against having ..'s in the path such that the server goes outside the
 * cwd.
 * <p>
 *
 * These days, modern browsers may have a security policy that defaults to
 * blocking requests to unusual ports, like 6000.  As of this writing, 6000
 * was blocked in Mozilla, because it's used for X/11.  If this is a problem,
 * you can always just use curl to get around this.  If you want to use
 * Mozilla and it someday blocks port 6001, this can be overridden
 * with the network.security.ports.banned.override config property,
 * which contains a comma-delimited list of allowed ports.  Go into
 * about:config, search for that property, and if it's not there, create
 * it (right-click in the results area, New -> String).  cf.
 * https://support.mozilla.org/en-US/questions/1083282 ,
 * http://kb.mozillazine.org/Network.security.ports.banned.override
 * <p>
 *
 * Version 1.0 written 3/27/15

 * @author Bill Foote
 * *
 * @version 1.1, 4/4/16
 * @version 1.2, 8/9/16 (adds TLS/SSL support)
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
        var ballot : Ballot,
        val lock : Lock,
        val voteReceived : Condition) : QueryListener(6001, false)
{
    override fun getHandler(query: String, rawOut: OutputStream, out: PrintWriter,
                            user : InetAddress): QueryHandler?
    {
        println("""Query is "$query"""")
        return BallotQuery(ballot, rawOut, out, user, lock)
    }

    override fun handlePost(headers: HashMap<String, String>, input: BufferedInputStream,
                            user : InetAddress)
    {
        var remaining = headers["Content-Length"]?.toLong()
        val contentType = headers["Content-Type"]
        if (remaining == null) {
            println("POST error:  No content length")
            return;
        }
        if (contentType != "text/plain") {
            println("POST warning:  contentType is $contentType, not application/octet-stream")
            println("I'll upload it, but you get what you get.")
        }
        println("length is $remaining")
        var found : Int? = null
        var round : Int? = null
        val votes = mutableSetOf<Int>()
        while (remaining > 0) {
            val ch = input.read();
            if (ch in '0'.toInt() .. '9'.toInt()) {
                val d = ch - '0'.toInt()
                found = if (found == null)  d  else  found * 10 + d
            } else if (ch == '='.toInt()) {
                if (found == null) {
                    println("parse error:  found is null")
                } else {
                    if (found >= 0) {   // If this isn't -1 from round, below
                        votes.add(found)
                    }
                    found = null
                }
            } else if (ch == 'r'.toInt()) {
                if (found == null) {
                    println("parse error:  found is null for round")
                } else {
                    round = found
                    found = -1      // Skip error when we see the '='
                }
            } else if (found != null) {
                println("""parse error:  no "=" after number""")
                found = null;
            }
            remaining--;
        }
        lock.withLock {
            if (ballot.round == round && !ballot.voted.contains(user)) {
                for (i in votes) {
                    ballot.candidates[i].votes++
                }
                ballot.voted.add(user)
                voteReceived.signalAll()
            }
        }
    }


    val publicURL: String @Throws(IOException::class)
        get() {
            val scheme = if (enableSsl) "https" else "http"
            return scheme + "://" + localInetAddress.hostAddress + ":" + port + "/"
        }

}

