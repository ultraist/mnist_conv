# simhash
use strict;
use warnings;
use Storable qw(retrieve nstore);
use Bit::Vector;
use Math::Trig qw(pi);

use constant {
  EPS => 1,
  K => 32,
  MNIST_VEC_DIM => 196
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
  my $simhash;
  
  print "loading .. ok\n";
  
  if (-f "simhash.bin") {
    $simhash = retrieve("simhash.bin");
  } else {
    $simhash = make_simhash_index($trainset);
    nstore($simhash, "simhash.bin");
  }
  
  foreach my $test_label (sort { $a <=> $b } keys(%$testset)) {
    my $test_mat = $testset->{$test_label};
    foreach my $test_vec (@$test_mat) {
      my $label = predict_label($test_vec, $simhash, $trainset);
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

sub bit_count32
{
  my $x = shift;
  $x = $x = (($x >> 1) & 0x55555555);
  $x = ($x & 0x33333333) + (($x >> 2) & 0x33333333);
  $x = ($x + ($x >> 4)) & 0x0f0f0f0f;
  $x = $x + ($x >> 8);
  $x = $x + ($x >> 16);
  return $x & 0x0000003F;
}

sub hamming
{
  my ($a, $b) = @_;
  return bit_count32($a ^ $b);
}

sub box_muller {
  my ($u, $s) = @_;
  my ($rand1, $rand2) = (rand(1), rand(1));
  return ($s * sqrt(-2.0 * log($rand1)) * sin(2.0 * pi() * $rand2)) + $u;
}

sub norm
{
  my ($vec) = @_;
  my $np = 0;
  for (my $i = 0; $i < scalar(@$vec);++$i) {
    $np += $vec->[$i] * $vec->[$i];
  }
  return sqrt($np);
}

sub dot
{
  my ($vec1, $vec2) = @_;
  my $ip = 0;
  for (my $i = 0; $i < scalar(@$vec1);++$i) {
    $ip += $vec1->[$i] * $vec2->[$i];
  }
  return $ip;
}

sub cosine_dist
{
  my ($vec1, $vec2) = @_;
  my $n = norm($vec1) * norm($vec2);
  
  if ($n == 0.0) {
    return 0.0;
  }
  
  return 2.0 - (1.0 + dot($vec1, $vec2) / $n);
}

sub calc_simhash
{
  my ($vec, $h, $k) = @_;
  my $hash = 0;
  
  for (my $i = 0; $i < $k; ++$i) {
    my $th = 0.0;
    for (my $j = 0; $j < scalar(@$vec); ++$j) {
      $th += $vec->[$j] * $h->[$i]->[$j];
    }
    if ($th >= 0) {
      $hash |= (1 << $i);
    }
  }
  
  return $hash;
}

sub make_simhash_index
{
  my $trainset = shift;
  my $simhash = { h => undef, hash => {}};
  my $h = [];
  my $c = 0;
  
  for (my $i = 0; $i < K; ++$i) {
    $h->[$i] = [];
    for (my $j = 0; $j < MNIST_VEC_DIM; ++$j) {
      $h->[$i]->[$j] = box_muller(0.0, 1.0);
    }
  }
  $simhash->{h} = $h;
  
  foreach my $label (sort { $a <=> $b } keys(%$trainset)) {
    my $mat = $trainset->{$label};
    
    $simhash->{hash}->{$label} = [];
    foreach my $vec (@$mat) {
      push(@{$simhash->{hash}->{$label}}, calc_simhash($vec, $h, K));
      printf("calc_simhash .. %d\r", ++$c);
    }
  }
  
  return $simhash;
}

sub predict_label
{
  my ($test_vec, $simhash, $trainset) = @_;
  return nn($test_vec, $simhash, $trainset);
}

sub nn
{
  my ($test_vec, $simhash, $trainset) = @_;
  my %vote;
  my @result;
  my $label;
  my @nn;
  my $hash = calc_simhash($test_vec, $simhash->{h}, K);
  my $min_dist = 1e64;
  
  foreach my $num (sort keys(%{$simhash->{hash}})) {
    my $mat = $simhash->{hash}->{$num};
    for (my $i = 0; $i < scalar(@$mat); ++$i) {
      my $hash_dist = hamming($hash, $mat->[$i]);
      if ($hash_dist < $min_dist) {
        $min_dist = $hash_dist;
      }
      if ($hash_dist <= $min_dist + EPS) {
        push(@nn, {
          label => $num, 
          dist => cosine_dist($test_vec, $trainset->{$num}->[$i])
        });
      }
    }
  }
  # 1-nearest neighbor
  @nn = sort { $a->{dist} <=> $b->{dist} } @nn;
  $label = $nn[0]->{label};
  
  return $label;
}
