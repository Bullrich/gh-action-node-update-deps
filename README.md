# Update node scoped dependencies

Updates Node scoped dependencies to latest and creates a pull request with the changes.

This project was forked from [neverendingqs/gh-action-node-update-deps](https://github.com/neverendingqs/gh-action-node-update-deps) 
and modified to work with a single scope by using [update-by-scope](https://www.npmjs.com/package/update-by-scope)

## Example usage

```yaml
name: Scheduled dependencies update
on:
  schedule:
    - cron: '0 15 * * 2'
jobs:
  update-deps:
    name: Update Node dependencies
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: Bullrich/update-node-scoped-dependencies@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}       # NPM token to use when `npm-registry-*` configs are set
        with:
          commit-message-prefix: fix                # defaults 'chore'
          git-user-email: myemail@example.com       # defaults to '41898282+github-actions[bot]@users.noreply.github.com'
          git-user-name: Test                       # defaults to 'github-actions[bot]'
          npm-registry-scope: '@thescope'           # Scope to update. Required
          npm-registry-url: 'https://domain/pkgs'   # Registry where the scope can be available. Optional.
          pre-commit-script: npm run build          # defaults to not running anything
          pull-request-labels: test                 # defaults to 'dependencies'
          requested-user: bullrich                  # Not required. User to request the review
          requested-team: frontend-devs             # Not required. Team to request the review
```
