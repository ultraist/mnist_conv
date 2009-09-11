use strict;
use warnings;
use Storable qw(retrieve);
use constant {
  M => 200,
  K => 5
};
$| = 1;
$SIG{INT} = sub { print "\n"; die; };

test();

sub test 
{
  #srand(time());
  
  print "loading .. \r";
  
  my ($csv, $data_file, $label_file) = @_;
  my $trainset = retrieve("mnist_train.bin");
  my $testset = retrieve("mnist_test.bin");
  my $n = 0;
  my $correct = 0;
  
  print "loading .. ok\n";
  
  foreach my $test_label (sort { $a <=> $b } keys(%$testset)) {
    my $test_mat = $testset->{$test_label};
    foreach my $test_vec (@$test_mat) {
      my $label = predict_label($test_vec, $trainset);
      # test
      if ($label == $test_label) {
        ++$correct;
      }
      ++$n;
      printf("test [$test_label] .. %.2f (%d/%d)\r", 100.0 * $correct / $n, $correct, $n);
    }
  }
  print "\n";
}

sub predict_label
{
  my ($test_vec, $trainset) = @_;
  return nn($test_vec, $trainset);
}

sub nn
{
  my ($test_vec, $trainset) = @_;
  my %vote;
  my @result;
  my $label;
  
  # bagging
  do {
    my @samples;
    my $min_dist = 1e+64;
    # sampling
    for (1 .. M) {
      foreach my $num (keys(%$trainset)) {
        my $mat = $trainset->{$num};
        my $rand_idx = int(rand(scalar(@$mat)));
        my $dist = distance($test_vec, $mat->[$rand_idx], $min_dist);
        if (defined($dist)) {
          push(@samples, { 
            label => $num, 
            dist => $dist
          });
          if ($dist < $min_dist) {
            $min_dist = $dist;
          }
        }
      }
    }
    # nearest neighbor
    @samples = sort { $a->{dist} <=> $b->{dist} } @samples;
    $label = $samples[0]->{label};
  } while (++$vote{$label} < K);
  
  return $label;
}

sub distance
{
  my ($vec1, $vec2, $min_dist) = @_;
  my $dist = 0;
  my $n_1 = int(scalar(@$vec1) * 0.25);
  my $n_2 = $n_1 * 2;
  my $n_3 = $n_1 * 3;
  my $n_4 = scalar(@$vec1)-1;
  
  for my $i ($n_1 + 1 ..  $n_2) {
    $dist += ($vec1->[$i] - $vec2->[$i]) ** 2;
  }
  if ($dist > $min_dist) {
    return undef;
  }
  
  for my $i ($n_2 + 1 .. $n_3) {
    $dist += ($vec1->[$i] - $vec2->[$i]) ** 2;
  }
  if ($dist > $min_dist) {
    return undef;
  }
  
  for my $i (0 ..  $n_1) {
    $dist += ($vec1->[$i] - $vec2->[$i]) ** 2;
  }
  if ($dist > $min_dist) {
    return undef;
  }
  
  for my $i ($n_3 + 1 .. $n_4) {
    $dist += ($vec1->[$i] - $vec2->[$i]) ** 2;
  }
  
  return $dist;
}
