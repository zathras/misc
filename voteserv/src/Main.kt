/**
 * Created by Bill Foote on 10/21/16
 *
 *  This little program implements a voting server.  I hacked it together
 *  by modifying simples (http://simples.jovial.com/), for use in my
 *  Girls Who Code club.  We're having a vote on the domain name of
 *  the class project, and it seemed fitting to do on-line voting in
 *  class.
 *
 *  The voting algorithm is to have several rounds of voting, where in each
 *  round we eliminate the choice(s) with the lowest number of votes, viz:
 *
 *      candidates = a list of candidate names
 *      while there's more than one candidate {
 *          for each voter {
 *              Present them with a list of candidates in random order
 *              have them vote for the names they like
 *          }
 *          minVotes = the lowest number of votes any candidate got
 *          remove all candidates that got minVotes votes
 *      }
 *      The remaining candidate is the winner
 *
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
import java.util.concurrent.locks.Condition
import java.util.concurrent.locks.Lock
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock


/**
 * A litle data holder for a candidate name, with a space for tracking how
 * many votes it has in the current round.
 */
data class Candidate(
        val name : String,
        var votes : Int = 0
)

/**
 * A ballot used in a round of voting.  We track who has voted so far
 * by IP address, to discourage multiple votes.
 */
data class Ballot(
        var candidates : Array<Candidate>,
        var round : Int = 1,
        val voted : MutableSet<InetAddress> = mutableSetOf<InetAddress>(),
        val timestamp : Long = System.currentTimeMillis()
) {
    /**
     * Prepeare for a new round of voting, by incrementing the round counter,
     * and initializing the vote count for each candidate to zero.
     */
    fun startNextRound(candidates : Array<Candidate>){
        this.candidates = candidates
        for (c in candidates) {
            c.votes = 0
        }
        round++
        voted.clear()
    }

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
    //
    // Make a ballot consisting of a list of all of our candidates.
    //
    /*
    var ballot = Ballot(arrayOf(
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
    */
    var ballot = Ballot(arrayOf(
            Candidate("Spinach"),
            Candidate("Brussel Sprouts"),
            Candidate("Chocolate")
    ))

    //
    // Our http server is multithreaded, so we need to deal with locking.
    // One lock and one condition variable will do.  We just use the classic
    // old-school Java wait/notifyAll paradigm.
    //
    val lock : Lock = ReentrantLock()
    val gotNews = lock.newCondition()

    //
    // Create an HTTP server to serve our ballot, and tell us when votes are
    // received (via lock and gotNews).  Start it up in a new thread.
    //
    val sh = SimpleHttp(ballot, lock, gotNews)
    println()
    println("Cast your votes at ${sh.publicURL}!")
    println()
    Thread(sh).start()

    //
    // Listen to the keyboard, so an operator can start a new round of voting
    // when all the votes have been cast in the current round.  This happens
    // in its own thread, too.
    //
    Thread ({
        while (true) {
            println("Keyboard commands:  r = new round, q = quit")
            val s = readLine()
            if (s == "r") {
                lock.withLock {
                    val winners = calculateWinners(ballot.candidates)
                    ballot.startNextRound(winners)
                    println("Starting round ${ballot.round} with ${winners.size} candidates...")
                    gotNews.signalAll()
                }
            } else if (s == "q") {
                System.exit(0)
            } else {
                println("""Command "$s" not recognized.""")
            }
        }
    }).start()

    // Print out the ballot results as news comes in
    while (true) {
        lock.withLock {
            gotNews.await()
            println("Ballot round ${ballot.round}")
            println("  Voters:  ${ballot.voted}")
            println()
            println("  Votes so far:")
            for (c in ballot.candidatesByVotes()) {
                println("    ${c.votes} for ${c.name}")
            }
            println()
        }
    }
}

/**
 * Calculate the winners of this round of voting, as follows:
 *
 *     Figure out the maximum and minimum number of votes any candidate got
 *     if maximum == minimum
 *         everybody wins -- the next round will have the same slate of candidates
 *     else
 *         Any candidate that got more than the minimum # of votes is a winner
 */
fun calculateWinners(candidates : Array<Candidate>) : Array<Candidate> {
    val winners = mutableListOf<Candidate>()
    var minVotes = candidates[0].votes;
    var maxVotes = minVotes;
    for (c in candidates) {
        if (c.votes > maxVotes) {
            maxVotes = c.votes
        }
        if (c.votes < minVotes) {
            minVotes = c.votes
        }
    }
    println()
    println("***************  RESULTS  ****************")
    println()
    println("    The candidate with the most votes got $maxVotes.")
    println("    The candidate with the least votes got $minVotes.")
    println()
    for (c in candidates) {
        if (c.votes > minVotes || minVotes == maxVotes) {
            winners.add(c)
        }
    }
    return winners.toTypedArray()
}
