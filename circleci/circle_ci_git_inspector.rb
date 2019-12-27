#
# To update this script, please update in github.com/truecoach/ops/circleci via
# pull request, then copy-paste the updated version here.
#
class CircleCiGitInspector
  DEVELOP_BRANCH = 'develop'
  MASTER_BRANCH = 'master'

  def deployed?
    current_branch == MASTER_BRANCH
  end

  def merged?
    current_branch == DEVELOP_BRANCH
  end

  def pr_exists?
    !ENV['CIRCLE_PULL_REQUEST'].nil?
  end

  def titles
    commit_messages(git_opts: ['--pretty=format:"%s"']).split("\n")
  end

  def commit_messages(git_opts: [])
    @_commit_messages ||= begin
      return git_log_master_messages(git_opts) if deployed?
      return git_log('origin/master..origin/develop', opts: git_opts) if merged?

      git_log("origin/develop..#{current_branch}", opts: git_opts)
    rescue Exception => e
      puts ""
      puts "ERROR: Failed to parse commit messages: #{e.message}"
      puts ""
      ""
    end
  end

  def git_log_master_messages(git_opts)
    # attempts to read commits messages between most recent master SHA
    # and SHA of last master build in Circle
    left, right = compare_url[/compare\/.*\.\.\..*$/].gsub('compare/', '').split('...')

    git_log("#{left}...#{right}", opts: git_opts)
  end

  def git_log(diff, opts: [])
    `git log #{diff} --no-merges #{opts.join(' ')}`.chomp
  end

  def compare_url
    ENV['CIRCLE_COMPARE_URL'].to_s
  end

  def current_branch
    @_current_branch ||= `git rev-parse --abbrev-ref HEAD`.chomp
  end
end
