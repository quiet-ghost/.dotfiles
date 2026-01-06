export const NotificationPlugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  return {
    event: async ({ event }) => {
      // Send notification on session completion
      if (event.type === "session.idle") {
        await $`notify-send -i dialog-information -u normal "opencode" "Opencode has completed the task!"`;
      }
    },
  };
};
