module.exports = async({process, github, context, steps}) => {
  const run_url = process.env.GITHUB_SERVER_URL + '/' + process.env.GITHUB_REPOSITORY + '/actions/runs/' + process.env.GITHUB_RUN_ID
  const run_link = '<a href="' + run_url + '">Actions</a>.'
  const fs = require('fs')
  const plan_file = fs.readFileSync('apply.out', 'utf8') +"\n"+fs.readFileSync('plan.out', 'utf8')
  const plan = plan_file.length > 65000 ? plan_file.toString().substring(0, 65000) + " ..." : plan_file
  const truncated_message = plan_file.length > 65000 ? "Output is too long and was truncated. You can read full Plan in " + run_link + "<br /><br />" : ""

  const creator = context.payload.sender.login
  const opts = github.rest.issues.listForRepo.endpoint.merge({
    ...context.issue,
    creator,
    state: 'closed'
  })
  const issues = await github.paginate(opts)

  const pr = context.issue.number || issues[0].number

  const output = `## Terraform \`ss\`
  #### Format and Style 🖌\`${steps.fmt.outcome}\`
  #### Initialization ⚙️\`${steps.init.outcome}\`
  #### Validation 🤖\`${steps.validate.outcome}\`
  #### Plan 📖\`${steps.plan.outcome}\`
  #### Plan Request Change 📖\`${steps.plan_reqchange.outcome}\`
  #### Apply 📖\`${steps.apply.outcome}\`

  <details><summary>Show Details</summary>

  \`\`\`terraform

  ${plan}

  \`\`\`

  </details>
  ${truncated_message}
  Results for commit: ${github.event.pull_request.head.sha}

  *Pusher: @${github.actor}, Action: \`${github.event_name}\`, Working Directory: \`ss\`, Workflow: \`${github.workflow}\`*`;
    
  await github.rest.issues.createComment({
    issue_number: pr,
    owner: context.repo.owner,
    repo: context.repo.repo,
    body: output
  })
}