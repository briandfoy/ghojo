#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;

my( $user, $field ) = @ARGV;
$field //= 'full_name';

my $callback = sub ( $repo, $tx ) {
	$repo->$field();
	};

my $result = Ghojo->new->get_repos_for_username( $user, $callback );

if( $result->is_success ) {
	say "Found " . $result->value_count . " repos";
	my $count = 1;
	$result->values->map( sub {
		say "$_";
		$count++;
		});
	exit;
	}
else {
	say "There was an error";
	say $result->message;

	if( $result->extras->{tx}->res->code == 404 ) {
		say "User <$user> not found";
		exit 1;
		}
	else {
		say 'Unspecified error';
		exit 9;
		}
	}

__END__
$VAR1 = bless( {
                 'forks_count' => 0,
                 'id' => 69706153,
                 'notifications_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/notifications{?since,all,participating}',
                 'watchers' => 0,
                 'deployments_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/deployments',
                 'git_url' => 'git://github.com/BurnItToTheGround/test_repo.git',
                 'homepage' => undef,
                 'subscription_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/subscription',
                 'name' => 'test_repo',
                 'git_refs_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/git/refs{/sha}',
                 'has_downloads' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                 'issue_events_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/issues/events{/number}',
                 'teams_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/teams',
                 'stargazers_count' => 0,
                 'url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo',
                 'open_issues' => 3,
                 'languages_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/languages',
                 'contributors_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/contributors',
                 'events_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/events',
                 'size' => 0,
                 'created_at' => '2016-09-30T22:24:31Z',
                 'hooks_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/hooks',
                 'git_tags_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/git/tags{/sha}',
                 'keys_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/keys{/key_id}',
                 'clone_url' => 'https://github.com/BurnItToTheGround/test_repo.git',
                 'statuses_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/statuses/{sha}',
                 'git_commits_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/git/commits{/sha}',
                 'blobs_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/git/blobs{/sha}',
                 'fork' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
                 'downloads_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/downloads',
                 'updated_at' => '2016-09-30T22:24:31Z',
                 'compare_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/compare/{base}...{head}',
                 'private' => $VAR1->{'fork'},
                 'has_pages' => $VAR1->{'fork'},
                 'open_issues_count' => 3,
                 'commits_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/commits{/sha}',
                 'stargazers_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/stargazers',
                 'archive_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/{archive_format}{/ref}',
                 'pulls_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/pulls{/number}',
                 'tags_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/tags',
                 'html_url' => 'https://github.com/BurnItToTheGround/test_repo',
                 'labels_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/labels{/name}',
                 'language' => undef,
                 'default_branch' => 'master',
                 'svn_url' => 'https://github.com/BurnItToTheGround/test_repo',
                 'forks_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/forks',
                 'mirror_url' => undef,
                 'merges_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/merges',
                 'description' => 'A repo that I can use to test the GitHub API',
                 'milestones_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/milestones{/number}',
                 'collaborators_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/collaborators{/collaborator}',
                 'has_issues' => $VAR1->{'has_downloads'},
                 'has_wiki' => $VAR1->{'has_downloads'},
                 'subscribers_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/subscribers',
                 'watchers_count' => 0,
                 'trees_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/git/trees{/sha}',
                 'releases_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/releases{/id}',
                 'full_name' => 'BurnItToTheGround/test_repo',
                 'issue_comment_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/issues/comments{/number}',
                 'owner' => {
                            'site_admin' => $VAR1->{'fork'},
                            'html_url' => 'https://github.com/BurnItToTheGround',
                            'organizations_url' => 'https://api.github.com/users/BurnItToTheGround/orgs',
                            'subscriptions_url' => 'https://api.github.com/users/BurnItToTheGround/subscriptions',
                            'avatar_url' => 'https://avatars.githubusercontent.com/u/22552550?v=3',
                            'id' => 22552550,
                            'gravatar_id' => '',
                            'following_url' => 'https://api.github.com/users/BurnItToTheGround/following{/other_user}',
                            'gists_url' => 'https://api.github.com/users/BurnItToTheGround/gists{/gist_id}',
                            'repos_url' => 'https://api.github.com/users/BurnItToTheGround/repos',
                            'events_url' => 'https://api.github.com/users/BurnItToTheGround/events{/privacy}',
                            'starred_url' => 'https://api.github.com/users/BurnItToTheGround/starred{/owner}{/repo}',
                            'type' => 'User',
                            'login' => 'BurnItToTheGround',
                            'url' => 'https://api.github.com/users/BurnItToTheGround',
                            'received_events_url' => 'https://api.github.com/users/BurnItToTheGround/received_events',
                            'followers_url' => 'https://api.github.com/users/BurnItToTheGround/followers'
                          },
                 'issues_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/issues{/number}',
                 'pushed_at' => '2016-09-30T22:24:31Z',
                 'comments_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/comments{/number}',
                 'branches_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/branches{/branch}',
                 'assignees_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/assignees{/user}',
                 'forks' => 0,
                 'contents_url' => 'https://api.github.com/repos/BurnItToTheGround/test_repo/contents/{+path}',
                 'ssh_url' => 'git@github.com:BurnItToTheGround/test_repo.git'
               }, 'Ghojo::Data::Repo' );
