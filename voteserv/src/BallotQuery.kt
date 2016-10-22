import server.QueryHandler
import java.io.*
import java.net.InetAddress
import java.util.*
import java.util.concurrent.locks.Lock
import kotlin.concurrent.withLock

class BallotQuery(val ballot : Ballot, rawOut: OutputStream, out: PrintWriter,
                  val user : InetAddress, val lock : Lock)
            : QueryHandler(rawOut, out) {

    override fun run() {
        startHttpResult(200)
        startHtml("Voting round ${ballot.round}")
        var voted = true;
        lock.withLock {
            voted = ballot.voted.contains(user)
        }
        if (voted) {
            out.println("<br><br><br><br><br>")
            out.println("<h4>Waiting for voting results...</h4>")
        } else {
            val round = ballot.round
            out.println("""<form enctype="text/plain" action="/" method="post">""")
            out.println("""  <input type="hidden" id="${round}r" name="${round}r" value="y">""")
            val lines = Array<String>(ballot.candidates.size, { i ->
                """<input type="checkbox" name="$i" id="$i" value="y">""" +
                """  <label for="$i">${ballot.candidates[i].name}</label>""" +
                """<br>"""
            })
            // Randomize the order of the ballot
            val rand = Random()
            for (i in lines.indices) {
                val j = rand.nextInt(lines.size)
                val c = lines[i]
                lines[i] = lines[j]
                lines[j] = c
            }
            out.println("Check the boxes for the names you like, then press the Vote button.<br><br>")
            for (i in lines.indices) {
                out.println(lines[i])
            }
            out.println("<br>")
            out.println("""<input type="submit" value="Vote"></form>""")
        }
        endHtml();
    }
}
