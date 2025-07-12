{ ... }:
{
  enable = true;
  userName = "Ananth Bhaskararaman";
  userEmail = "antsub@gmail.com";

  aliases = {
    a = "add";
    b = "branch";
    c = "commit";
    p = "push";
    r = "reset";
    s = "status -sb";
    sw = "switch";
    co = "checkout";
    cp = "cherry-pick";
  };

  extraConfig = {
    core.editor = "nvim";
    core.pager = "delta";
    user.useConfigOnly = "true";
    init.defaultBranch = "main";

    color = {
      ui = "true";
      diff = "auto";
      status = "auto";
      branch = "auto";
    };

    advice = {
      pushNonFastForward = "false";
      statusHints = "false";
      commitBeforeMerge = "false";
      resolveConflict = "false";
      implicitIdentity = "false";
      detachedHead = "false";
    };

    push.autoSetupRemote = true;
    rerere.enabled = "true";
    column.ui = "auto";
    branch.sort = "-committerdate";
    merge.conflictStyle = "zdiff3";
    diff.algorithm = "histogram";
    transfer.fsckObjects = "true";
    fetch.fsckObjects = "true";

    receive.fsckObjects = "true";
  };
}
