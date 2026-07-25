import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface Question {
  text: string;
}

function textContent(content: unknown): string {
  if (!Array.isArray(content)) return "";
  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        typeof part === "object" &&
        part !== null &&
        "type" in part &&
        part.type === "text" &&
        "text" in part &&
        typeof part.text === "string",
    )
    .map((part) => part.text)
    .join("\n");
}

function extractQuestions(text: string): Question[] {
  const seen = new Set<string>();
  const matches = text.match(/[^\n.!?]*\?+(?:["')\]]+)?/g) ?? [];
  return matches.flatMap((match) => {
    const question = match.replace(/^[\s>*-]+/, "").trim();
    const key = question.toLowerCase();
    if (!question || seen.has(key)) return [];
    seen.add(key);
    return [{ text: question }];
  });
}

export default function answerExtension(pi: ExtensionAPI): void {
  const answer = async (ctx: Parameters<Parameters<ExtensionAPI["registerCommand"]>[1]["handler"]>[1]) => {
    if (!ctx.hasUI) {
      ctx.ui.notify("/answer requires interactive mode", "error");
      return;
    }

    const branch = ctx.sessionManager.getBranch();
    let assistantText = "";
    for (let index = branch.length - 1; index >= 0; index--) {
      const entry = branch[index];
      if (entry?.type !== "message" || entry.message.role !== "assistant") continue;
      assistantText = textContent(entry.message.content).trim();
      if (assistantText) break;
    }

    const questions = extractQuestions(assistantText);
    if (questions.length === 0) {
      ctx.ui.notify("No questions found in the latest assistant response", "info");
      return;
    }

    const answers: string[] = [];
    for (const [index, question] of questions.entries()) {
      const response = await ctx.ui.input(
        `Question ${index + 1}/${questions.length}: ${question.text}`,
        "Type an answer or Esc to cancel",
      );
      if (response === undefined) {
        ctx.ui.notify("Answering cancelled", "info");
        return;
      }
      answers.push(response.trim() || "(no answer)");
    }

    const message = ["Here are my answers:", ""];
    questions.forEach((question, index) => {
      message.push(`Q: ${question.text}`, `A: ${answers[index]}`, "");
    });
    pi.sendUserMessage(message.join("\n").trim(), {
      deliverAs: ctx.isIdle() ? undefined : "followUp",
    });
  };

  pi.registerCommand("answer", {
    description: "Answer questions from the latest assistant response",
    handler: async (_args, ctx) => answer(ctx),
  });
}
