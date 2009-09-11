package MNIST;
use strict;
use warnings;
use Carp;
use File::Binary;

sub load
{
  my ($data_file, $label_file) = @_;
  return _load(0, $data_file, $label_file);
}

sub load_half
{
  my ($data_file, $label_file) = @_;
  return _load(1, $data_file, $label_file);
}

sub _load
{
  my ($half, $data_file, $label_file) = @_;
  my $data = new File::Binary($data_file) || Carp::croak("$data_file: $!\n");
  my $label = new File::Binary($label_file) || Carp::croak("$label_file:  $!\n");
  
  $data->set_endian($File::Binary::LITTLE_ENDIAN);
  $label->set_endian($File::Binary::LITTLE_ENDIAN);
  
  $label->seek(4);
  $data->seek(4);
  my $count = $label->get_ui32();
  $data->get_ui32(); # seek
  
  my $dataset = {};
  my $rows = $data->get_ui32();
  my $cols = $data->get_ui32();
  
  for (my $i = 0; $i < $count; ++$i) {
    my $num = $label->get_ui8();
    my $vec = [];
    if (!defined($dataset->{$num})) {
      $dataset->{$num} = [];
    }
    for (my $j = 0; $j < $rows * $cols; ++$j) {
      push(@$vec, $data->get_ui8());
    }
    push(@{$dataset->{$num}}, $vec);
  }
  
  # half size
  if ($half) {
    _conv_half($dataset, $rows, $cols);
    $rows = int($rows / 2);
    $cols = int($cols / 2);
  }
  
  return ($dataset, $rows, $cols);
}

sub _conv_half
{
  my ($dataset, $rows, $cols) = @_;
  my $new_cols = int($cols / 2);
  my $new_rows = int($rows / 2);
  
  foreach my $num (keys(%$dataset)) {
    my $mat = $dataset->{$num};
    my $half_mat = [];
    
    foreach my $vec (@$mat) {
      # resize
      my $half_vec = [];
      for (my $y = 0; $y < $new_rows; ++$y) {
        for (my $x = 0; $x < $new_cols; ++$x) {
          my $px = int(
          ( $vec->[($y * 2) * $cols + $x * 2]
          + $vec->[($y * 2) * $cols + $x * 2 + 1]
          + $vec->[($y * 2 + 1) * $cols + $x * 2]
          + $vec->[($y * 2 + 1) * $cols + $x * 2 + 1])
          * 0.25);
          $half_vec->[$y * $new_cols + $x] = $px;
        }
      }
      push(@$half_mat, $half_vec);
    }
    $dataset->{$num} = $half_mat;
  }
}

1;