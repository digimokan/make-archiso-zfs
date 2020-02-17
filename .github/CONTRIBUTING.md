# Contributing

## Git Workflow

### Initial Setup

1. [GITHUB PAGE] Fork the project repo:

    * click "fork" from https://github.com/digimokan/make-archiso-zfs

2. [LOCAL] Create local repo:

        $ git clone --recurse-submodules https://github.com/[your-github-username]/make-archiso-zfs

3. [LOCAL] Link upstream repo:

        $ git remote add upstream https://github.com/digimokan/make-archiso-zfs

### Development Workflow

1. Find the issue you have been assigned, or assign a needed issue to yourself.

2. [LOCAL] Retrieve all changes from upstream.  Update local master branch and
sync it with your forked origin repo.  Create new local branches to track
upstream branches you want to follow locally:

        $ git fetch upstream
        $ git checkout master
        $ git merge upstream/master
        $ git push origin master
        $ git branch --track [branch-name] upstream/[branch-name]

3. [LOCAL] Create and switch to a feature/fix branch for your issue:

        $ git checkout master
        $ git checkout -b feat-issuename

4. [LOCAL] Work on your feature branch:

        $ [edit existing files / new files]
        $ git add [existing/new files]
        $ git commit

5. [LOCAL] Periodically merge in upstream changes into your feature branch.
When working on feature branch for long periods, this merging reduces the
confusion that may come with a single large merge in step 8:

        $ git fetch upstream
        $ git checkout master
        $ git merge upstream/master
        $ git push origin master
        $ git checkout feat-issuename
        $ git merge master

6. [LOCAL] Periodically push your feature branch to your forked origin repo
(to back it up). If you have permission, also push your feature branch to
upstream (so that others may view and comment on your progress):

        $ git push origin feat-issuename
        $ git push upstream feat-issuename

7. [LOCAL] When complete with your feature branch, retrieve all changes from
upstream. Update local master branch and sync it with your forked origin repo.
Create new local branches to track new upstream branches you want to follow
locally. Update other existing local branches with their upstream counterparts:

        $ git fetch upstream
        $ git checkout master
        $ git merge upstream/master
        $ git push origin master
        $ git branch --track [new-branch-name] upstream/[new-branch-name]
        $ git checkout [other-local-branch]
        $ git merge upstream/[other-local-branch]

8. [LOCAL] Merge changes from retrieved upstream master branch into your feature
branch:

        $ git checkout feat-issuename
        $ git merge master

9. [LOCAL - AS NEEDED] If merge notifies of conflicts, determine conflict files.
Edit and correct conflict files.  Flag conflict files as "corrected" by adding
them. Finish the merge by committing:

        $ git status
        $ [edit and correct conflict files]
        $ git add [conflict files]
        $ git commit

10. [LOCAL] Condense all commits in your feature branch into one single commit:

        $ git rebase -i master

11. [LOCAL] Push your feature branch to your forked repo. If you have
permission, push it to upstream repo (if others want to pull it down and test
it). Since you condensed your commits, you will have to force/overwrite the
uncondensed commits that currently exist on origin and upstream:

        $ git push -f origin feat-issuename
        $ git push -f upstream feat-issuename

12. [GITHUB PAGE] Create pull request, specifying additions/changes and issue
number(s):

    * Pull request is FROM your-forked-repo/feat-issuename TO
      upstream-repo/master.

13. [GITHUB PAGE] If pull request rejected, begin again from Step #4.

14. [LOCAL] Delete the feature branch locally, from your forked origin repo, and
from upstream repo (if you pushed it to upstream in step 11):

        $ git branch -d feat-issuename
        $ git push origin --delete feat-issuename
        $ git push upstream --delete feat-issuename

### Merging Pull Requests

NOTE: do not merge your own pull requests.

1. [GITHUB PAGE] Make sure pull request commentary is properly descriptive.

2. [GITHUB PAGE] Review each changed/added line in each source file.

3. [GITHUB PAGE] Comment appropriately on specific source code sections.

4. [GITHUB PAGE] Merge or reject pull request.

