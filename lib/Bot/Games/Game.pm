package Bot::Games::Game;
use Bot::Games::OO::Game;
use DateTime;

has help => (
    is         => 'ro',
    isa        => 'Str',
    default    => 'This game doesn\'t have any help text!',
    command    => 1,
    needs_init => 0,
);

# XXX: traits has to be specified manually here because the metaclass option
# overrides anything set up by MetaRole - once MXAH can use traits, we should
# just use that instead.
has players => (
    metaclass  => 'Collection::Array',
    traits     => ['Bot::Games::Trait::Attribute::Command',
                   'Bot::Games::Trait::Attribute::Formatted'],
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
    default    => sub { [] },
    provides   => {
        push  => 'add_player',
        count => 'num_players',
    },
    command    => 1,
);
command 'num_players';

has start_time => (
    is         => 'ro',
    isa        => 'DateTime',
    default    => sub { DateTime->now },
    command    => 1,
    formatter  => sub { _diff_from_now(shift) },
);

has last_turn_time => (
    is         => 'rw',
    isa        => 'DateTime',
    command    => 1,
    formatter  => sub { _diff_from_now(shift) },
);

has is_over => (
    is         => 'rw',
    isa        => 'Bool',
    command    => 1,
);

sub turn {
    my $turn = inner();
    return $turn if defined($turn);
    return "Games must provide a turn method";
}
after turn => sub { shift->last_turn_time(DateTime->now) };

sub allow_new_player { 1 }
around add_player => sub {
    my $orig = shift;
    my $self = shift;
    if ($self->allow_new_player) {
        $self->$orig(@_);
        return 1;
    }
    return;
};

command cmdlist => sub {
    my $self = shift;
    my @commands;
    for my $method ($self->meta->get_all_methods) {
        push @commands, $method->name
            if $method->meta->can('does_role')
            && $method->meta->does_role('Bot::Games::Trait::Method::Command');
    }
    return \@commands;
}, needs_init => 0,
   formatter => sub {
       my $list = shift;
       return join ' ', sort map { '-' . $_ } @$list
   };

# XXX: this would be much nicer as an external module, but the only one that
# really does what i want (DateTime::Format::Human::Duration) has only had one
# release, which doesn't pass tests. bleh.
sub _diff_from_now {
    my ($dt) = @_;
    my $dur = DateTime->now - $dt;
    my @units = qw/weeks days hours minutes seconds/;
    $dur->in_units(@units);
    my @dur_values = map { $dur->$_ . " $_" } grep { $dur->$_ } @units;
    return join(', ', @dur_values) . " ago";
}

# this happens in Bot::Games, since we want to add the say method from there
#__PACKAGE__->meta->make_immutable;
no Bot::Games::OO;

1;
