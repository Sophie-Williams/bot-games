package Bot::Games::Game;
use Bot::Games::OO;
use DateTime;
use Time::Duration;
use List::MoreUtils qw(any);

has players => (
    traits     => [qw(Array)],
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
    default    => sub { [] },
    handles => {
        add_player  => 'push',
        num_players => 'count',
    },
    command    => 1,
);
command 'num_players';
command has_player => sub {
    my $self = shift;
    my ($player) = @_;
    return any { $_ eq $player } $self->players;
}, formatter => 'Bool';

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
    formatter  => sub {
        my $time = shift;
        return "Nobody has taken a turn yet!" if !$time;
        return _diff_from_now($time)
    },
);

sub default {
    my $self = shift;
    return "Games must provide a turn method" unless $self->can('turn');
    $self->turn(@_);
}
after default => sub { shift->last_turn_time(DateTime->now) };

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

sub _diff_from_now { ago(time - shift->epoch, 3) }

__PACKAGE__->meta->make_immutable;
no Bot::Games::OO;

1;
