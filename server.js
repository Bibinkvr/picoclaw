import express from "express"
import { runAgent } from "./picoclawAgent.js"

const app = express()
app.use(express.json())

app.post("/chat", async (req, res) => {
  const { message } = req.body
  const reply = await runAgent(message)
  res.json({ reply })
})

app.listen(process.env.PORT || 3000)
