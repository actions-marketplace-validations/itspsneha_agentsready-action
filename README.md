# AgentsReady GitHub Action

Can ChatGPT, Claude and Perplexity read and use your website? This action checks your site on every pull request or on a schedule. It posts the score, which AI agents get blocked, and the fixes in order. It can fail the build when a bot wall shuts agents out or the score drops below your bar.

It's free, needs no API key, and uses the same check as [agentsready.dev](https://agentsready.dev/?utm_source=github&utm_medium=action-readme).

![Example comment](https://agentsready.dev/og/linear.app)

## Use it

```yaml
# .github/workflows/agents-ready.yml
name: Agent ready
on:
  pull_request:
  schedule:
    - cron: "0 9 * * 1" # every Monday
permissions:
  pull-requests: write
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: itspsneha/agentsready-action@v1
        with:
          domain: example.com
          fail-under: 60
```

## Inputs

| Input | Default | What it does |
| --- | --- | --- |
| `domain` | (required) | The site to check |
| `job` | auto | The job an agent tries: `recommend`, `buy`, `signup`, `api` or `personal` |
| `fail-under` | `0` | Fail when the score is below this |
| `fail-on-bot-wall` | `true` | Fail when a firewall blocks AI agents |
| `comment` | `true` | Comment on pull requests, edited in place on later runs |

## Outputs

`score`, `level`, `bot-wall`, `report`. For example, `${{ steps.agents.outputs.score }}`.

## What it checks

60 points for what every site needs (agents get past the firewall, robots.txt lets AI agents in, the page renders without JavaScript, structured data, llms.txt) and 40 for the job: OpenAPI, MCP, self-serve API keys, OAuth self-registration, a checkout an agent can reach. It also measures, without scoring, which of seven named AI agents get the real page and how many tokens your homepage costs to read. [How the score works](https://agentsready.dev/standard).

Results are cached for up to 24 hours, so a fix you deploy shows up on the next day's run.

## Also

- In Claude, Cursor or VS Code: the [AgentsReady MCP server](https://agentsready.dev/mcp-server) runs the same check from your agent. `claude mcp add --transport http agentsready https://agentsready.dev/mcp`
- A README badge: `[![Agent ready](https://agentsready.dev/badge/example.com)](https://agentsready.dev/c/example.com)`

MIT licensed. Made by [Sneha](https://x.com/itspsneha).
