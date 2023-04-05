use v5.28;
package Ghojo::Scopes;
use experimental qw(signatures);

use Carp qw(carp);
use Mojo::Util qw(deprecated);

=encoding utf8

=head1 NAME

Ghojo::Scopes - Manages OAuth scopes

=head1 SYNOPSIS

	my $scopes = Ghojo::Scopes->new;
	$scopes->add_scopes( @scopes );

	# or in one step
	my $scopes = Ghojo::Scopes->new( @scopes );

	# check that the object recorded a particular scope
	if( $scopes->has_scope( 'repo' ) ) { ... }

	# check that one of the record scopes is or implies
	# the scope
	if( $scopes->satisfies( 'repo:status' ) ) { ... }

=head1 DESCRIPTION

GitHub's Personal Access Tokens rely on scopes to define what operations
it can do. This module manages and supports queries about sets of
scopes.

A Ghojo object automatically handles all this for you when you
authenticate with tokens.

On GitHub:

	https://docs.github.com/en/developers/apps/scopes-for-oauth-apps

=head2 Scope hierarchy

	repo
		repo:status
		repo_deployment
		public_repo
		repo:invite
		security_events
	admin:repo_hook
		write:repo_hook
		read:repo_hook
	admin:public_key
		write:public_key
		read:public_key
	admin:org_hook
	gist
	notifications
	user
		read:user
		user:email
		user:follow
	delete_repo
	write:discussion
		read:discussion
	write:packages
	read:packages
	delete:packages
	admin:gpg_key
		write:gpg_key
		read:gpg_key
	workflow

=head2 Methods



=over 4

=item * CLASS->new( SCOPES )


=cut

my( $raw, $scopes );
BEGIN {
	$raw = {
		'repo'             => [ qw( repo:status repo_deployment public_repo repo:invite security_events ) ],
		'workflow'         => [ ],
		'write:packages'   => [ qw( read:packages ) ],
		'delete:packages'  => [ ],
		'admin:org_hook'   => [ qw( write:org read:org manage_runners:org ) ],
		'admin:public_key' => [ qw( write:public_key read:public_key ) ],
		'admin:repo_hook'  => [ qw( write:repo_hook read:repo_hook ) ],
		'admin:org_hook'   => [ ],
		'gist'             => [ ],
		'notifications'    => [ ],
		'user'             => [ qw( read:user user:email user:follow) ],
		'delete_repo'      => [ ],
		'write:discussion' => [ qw( read:discussion ) ],
		'admin:enterprise' => [ qw( manage_runners:enterprise manage_billing:enterprise read:enterprise ) ],
		'project'          => [ qw( read:project ) ],
		'admin:gpg_key'    => [ qw( write:gpg_key read:gpg_key ) ],
		'admin:ssh_signing_key' => [ qw( write:ssh_signing_key read:ssh_signing_key ) ],
		};

	foreach my $parent ( keys $raw->%* ) {
		$scopes->{$parent}{parent} = undef;
		foreach my $child ( $raw->{$parent}->@* ) {
			$scopes->{$parent}{$child} = 1;
			$scopes->{$child}{parent} = $parent;
			}
		}
}

sub new ( $class, @scopes ) {
	my $self = bless { scopes => {} }, $class;
	$self->add_scopes( @scopes );
	$self;
	}

my sub _extract ( $tx, $header ) {
	split /\s*,\s*/, $tx->result->headers->header( $header ) // '';
	}

=item * CLASS->extract_scopes_from_tx( Mojo::Transaction )


=cut

sub extract_scopes_from ( $class, $tx ) {
	state %h = (
		has      => 'x-oauth-scopes',
		requires => 'x-accepted-oauth-scopes',
		);

	my %hash = map { $_, $class->new( _extract($tx, $h{$_}) ) } keys %h;
	return \%hash;
	}

=item * EITHER->is_defined( SCOPE )

Returns true is the scope is defined

=item * OBJ->add_scopes( SCOPES )

Add the scopes to the object

=item * OBJ->has_scope( SCOPE )

Returns true is the scopes includes SCOPE. This includes a scope that
implies other scopes.

=item * OBJ->has_scope( SCOPE )

Returns true is the scopes includes a scope that's the parent of
SCOPE. This includes a scope that implies other scopes.

=item * EITHER->parent( SCOPE )

Returns the parent of the scope (I<i.e.> C<repo> for C<repo:status>)
if the scope has a parent, and nothing otherwise. A scope that exists
and has no parent returns nothing.

=item * OBJ->has_parent_scope( SCOPE )

Returns true if the object has the parent scope to SCOPE, which means
it should have the permissions for SCOPE.

=item * OBJ->remove_scope( SCOPE )

Removes the scope.

=cut

sub is_defined ( $self, $scope ) { $scopes->{$scope} }

sub add_scopes ( $self, @scopes ) {
	my @added;
	foreach my $scope ( @scopes ) {
		unless( $self->is_defined( $scope ) ) {
			carp "Unrecognized scope <$scope>. Not adding!";
			next;
			}
		$self->{scopes}{$scope}++;
		push @added, $scope;
		}
	return @added;
	}

sub scopes ( $self ) {
	deprecated "scopes is deprecated. Use as_list instead";
	$self->as_list;
	}

sub as_list   ( $self ) { keys $self->{scopes}->%* }

sub has_scope ( $self, $scope ) { exists $self->{scopes}{$scope} }

sub parent ( $self, $scope ) {
	return unless $self->is_defined( $scope );
	$scopes->{$scope}{parent}
	}

sub has_parent_scope ( $self, $scope ) { $self->has_scope( $scopes->parent($scope) ) }

sub remove_scope ( $self, $scope )     { delete $self->{scopes}{$scope} }

=item * OBJ->normalize

Normalize the scopes this object is tracking. If the scope's parent
also exists in the object, the child scope is removed.

=cut

sub normalize ( $self ) {
	foreach my $scope ( $self->scopes ) {
		next if $self->has_parent_scope( $scope );
		$self->remove_scope( $scope );
		}
	}

=item * OBJ->normalized_scopes

Returns the list of normalized scopes. For example, if the scope list
has both C<repo> and C<repo:status>, only C<repo> comes back because it
contains

=cut

sub normalized_scopes ( $self ) {
	my @scopes;
	foreach my $scope ( $self->scopes ) {
		next if $self->has_parent_scope( $scope );
		push @scopes, $scope;
		}
	@scopes;
	}

=item * OBJ->satisfies( SCOPES )

Returns true if the scopes in the object satisfy the ones in the
argument.

=item * OBJ->satisfies_some( SCOPES )

Returns true if the scopes in the object satisfy at least one of
the scopes the argument.

=cut

sub satisfies ( $self, @scopes ) {
	foreach my $check ( @scopes ) {
		next if( $self->has_scope( $check ) or $self->has_scope( $scopes->{$check}{parent} ) );
		return 0;
		}
	return 1;
	}

sub satisfies_some ( $self, @scopes ) {
	foreach my $check ( @scopes ) {
		return 1 if( $self->has_scope( $check ) or $self->has_scope( $scopes->{$check}{parent} ) );
		}
	return 0;
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2023, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut
__PACKAGE__
