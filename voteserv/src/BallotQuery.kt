import server.QueryHandler
import java.io.*
import java.net.InetAddress
import java.util.*
import java.util.concurrent.locks.Lock
import kotlin.concurrent.withLock

class BallotQuery(val ballotIn : Ballot, rawOut: OutputStream, out: PrintWriter,
                  val user : InetAddress, val lock : Lock)
            : QueryHandler(rawOut, out) {


    override fun run() {
        var voted = false
        val ballot = lock.withLock {
            val b = ballotIn.copy()
            voted = b.voted.contains(user)
            b
        }

        startHttpResult(200)
        if (ballot.candidates.size == 1) {
            startHtml("Winner")
        } else {
            startHtml("Voting round ${ballot.round}")
        }
        if (voted) {
            out.println("<br><br><br><br><br>")
            out.println("<h4>Waiting for voting results...</h4>")
            out.println("<br><br><br>")
            out.println("""<center><font size="+2"><a href="/">Vote In Next Round</a></font></center>""")
        } else if (ballot.candidates.size == 1) {
            out.println("<br><br><br><br><br>")
            out.println("""<center><font size="+4"><font color="purple">""" +
                        """${ballot.candidates[0].name}</font> wins!</font></center>""")
        } else {
            out.println("""<form enctype="text/plain" action="/" method="post">""")
            out.println("""  <input type="hidden" id="${ballot.timestamp}t" name="${ballot.timestamp}t" value="y">""")
            out.println("""  <input type="hidden" id="${ballot.round}r" name="${ballot.round}r" value="y">""")
            val index = Array<Int>(ballot.candidates.size, { i -> i })
            // Randomize the order of the ballot
            val rand = Random()
            for (i in index.indices) {
                val j = rand.nextInt(index.size)
                val c = index[i]
                index[i] = index[j]
                index[j] = c
            }


            out.println("Check the boxes for the names you like, then press the Vote button.<br>")
            out.println("Pick as many names as you want.<br><br>")
            for (k in index.indices) {
                val i = index[k]
                out.println(
                        """<input type="checkbox" name="$i" id="$i" value="y">""" +
                        """  <label for="$i">${ballot.candidates[i].name}</label>""" +
                        """<br>"""
                )
            }
            out.println("<br>")
            out.println("""<input type="submit" value="Vote"></form>""")
        }
        endHtml();
    }
}
