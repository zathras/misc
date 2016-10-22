/**
 * Created by w.foote on 3/31/2016.
 */

import java.io.File
import java.io.IOException
import java.net.InetAddress
import java.security.SecureRandom

import server.ErrorQueryHandler
import server.QueryHandler
import server.QueryListener
import java.io.FileInputStream
import java.util.*
import java.util.concurrent.locks.Lock
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock


data class Candidate(val name : String, var votes : Int = 0)

data class Ballot(
        val candidates : Array<Candidate>,
        val round : Int = 1,
        var voted : MutableSet<InetAddress> = mutableSetOf<InetAddress>()
) {
    fun candidatesByVotes() : List<Candidate> =
        candidates.sortedWith(Comparator { a, b ->
            if (a.votes != b.votes) {
                b.votes - a.votes
            } else {
                a.name.compareTo(b.name, ignoreCase = true)
            }
        })
}

fun main(args:  Array<String>) {
    val ballot = Ballot(arrayOf(
            Candidate("FluffyBunnies"),
            Candidate("GlorpAndMath"),
            Candidate("witches-who-code"),
            Candidate("coding-learners"),
            Candidate("amazing"),
            Candidate("ardent"),
            Candidate("girslwhocode"),
            Candidate("2016coding"),
            Candidate("code-from-girls"),
            Candidate("frankenstein-sprite"),
            Candidate("PeaceGlorps"),
            Candidate("glorp"),
            Candidate("irvinegwc"),
            Candidate("SwaggyCodersOfIrvine"),
            Candidate("determined"),
            Candidate("difference")
    ))
    val lock : Lock = ReentrantLock()
    val gotNews = lock.newCondition()


    val sh = SimpleHttp(ballot, lock, gotNews)
    println()
    println("Cast your votes at ${sh.publicURL}!")
    println()
    Thread(sh).start()
    while (true) {
        lock.withLock {
            gotNews.await()
            println("Voters:  ${ballot.voted}")
            println()
            println("Votes so far:")
            for (c in ballot.candidatesByVotes()) {
                println("    ${c.votes} for ${c.name}")
            }
            println()
        }
    }
}
