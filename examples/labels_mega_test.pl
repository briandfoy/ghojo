#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'common_things.pl' }

use Mojo::Util qw(dumper);

use Ghojo;
$ENV{GHOJO_LOG_LEVEL} = log_level();
say "log_level is " . log_level();

my @repo = my( $owner, $repo ) = @ARGV;

my $hash = {
	username     => $owner,
	password     => password(),
	authenticate => 0,
	};

my $ghojo = Ghojo->new( $hash );
die "Could not log in!\n" if $ghojo->is_error;

my $result = $ghojo->get_repo( @repo );
if( $result->is_error ) {
	die $result->message;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# list the label names
my %labels;
{
say '-' x 50;
say "Labels are:";
my $callback = sub ( $item, @ ) {
	say "\t* ", $item->name;
	$labels{ $item->name }++;
	$item;
	};
my $result = $ghojo->labels( $owner, $repo, $callback );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# list the existing issues and their labels
my %issue_numbers;
{
say '-' x 50;
say "Issues are:";
my $callback = sub ( $item, @ ) {
	printf "%3d %s\n", $item->number, $item->title;
	$issue_numbers{ $item->number }++;
	my $callback = sub ( $item, @ ) {
		say "\t*" . $item->name;
		$item;
		};
	$ghojo->get_labels_for_issue( $owner, $repo, $item->number, $callback );
	};

$ghojo->all_issues_on_repo( @repo, $callback, { 'sort' => 'created', direction => 'asc' } );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create a new label
my $new_label = 'test label ' . time;
{
my $result = $ghojo->create_label( @repo, $new_label );
if( $result->is_error ) {
	die "Could not create label! " . $result->message;
	}
print "Added [$new_label]. Check GitHub. Return to continue...";
scalar <STDIN>;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# update new label color
my $new_color = '00FF00';
{
$ghojo->update_label( @repo, $new_label, { color => $new_color } );
print "Made $new_label color $new_color. Check GitHub. Return to continue...";
scalar <STDIN>;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# add label to issues
{
foreach my $issue_id ( keys %issue_numbers ) {
	$ghojo->add_labels_to_issue( $owner, $repo, $issue_id, $new_label );
	print "Added label to issue $issue_id. Check GitHub. Return to continue...";
	scalar <STDIN>;
	}
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create a new label name
my $updated_name = "$new_label (updated)",
{
my $result = $ghojo->update_label( @repo, $new_label, { name => $updated_name } );
if( $result->is_error ) {
	say "Could not update label! " . $result->message;
	say $result->extras->{tx}->req->to_string;
	say $result->extras->{tx}->res->to_string;
	}
print "Updated label name. Check GitHub. Return to continue...";
scalar <STDIN>;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# delete that new label
{
$ghojo->delete_label( @repo, $updated_name );
print "Deleting label [$new_label]. Check GitHub. Return to continue...";
scalar <STDIN>;
}
