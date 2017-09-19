#!/usr/bin/perl

# ==============================================================================
#   機能
#     ソートされた順序でファイルを検索する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2012-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
use strict;
use warnings;

use File::Find;
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);

my $s_err = "";
$SIG{__DIE__} = $SIG{__WARN__} = sub { $s_err = $_[0]; };

######################################################################
# 変数定義
######################################################################
my $EXCLUDE_PATTERN = "";
my $LINE_TERMINATOR = "\n";
my $FLAG_OPT_LONG = 0;

my @files = ();
my $result = 0;

######################################################################
# サブルーチン定義
######################################################################
sub USAGE {
	print STDOUT <<EOF;
Usage:
    find_sort.pl [OPTIONS ...] [DIR ...]

    DIR : Find files in the DIRs.

OPTIONS:
    --exclude=PATTERN
       Do not list any files whose filenames match the pattern.
    --print0
       Output lines on the standard output, followed by a null character.
       Specifying this option is effective only when '-l' option is NOT
       specified.
    -l
       Use a long listing format.
    --help
       Display this help and exit.
EOF
}

use Common_pl::Ls_file;

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
if ( not eval { GetOptionsFromArray( \@ARGV,
	"exclude=s" => sub {
		$EXCLUDE_PATTERN = $_[1];
	},
	"print0" => sub {
		$LINE_TERMINATOR = "\0";
	},
	"l" => sub {
		$FLAG_OPT_LONG = 1;
		$Common_pl::Ls_file::FLAG_OPT_LONG = 1;
	},
	"help" => sub {
		USAGE();exit 0;
	},
) } ) {
	print STDERR "-E $s_err\n";
	USAGE();exit 1;
}

# ファイルの処理
@files = @ARGV;
if ( @files == 0 ) {
	@files = (".");
}

#####################
# メインループ 開始 #
#####################

$SIG{__DIE__} = $SIG{__WARN__} = sub {
	print STDERR "-W $_[0]";
	$result = 1;
};
eval {
	find({
		preprocess => sub {
			use locale;
			sort {$a cmp $b} @_;
		},
		no_chdir => 1,
		wanted => sub {
			my $file;
			$file = $File::Find::name;
			if ( ( $EXCLUDE_PATTERN ne "" ) and ( $file =~ m#$EXCLUDE_PATTERN#s ) ) {
				$File::Find::prune = 1;
			} else {
				if ( not $FLAG_OPT_LONG ) {
					print "$file$LINE_TERMINATOR";
				} else {
					print LS_FILE("$file", "");
				}
			}
		},
	}, @files);
};
if ( $@ ne "" ) {
	print STDERR "-E $@\n";
	exit 1;
}

#####################
# メインループ 終了 #
#####################

# 作業終了後処理
exit $result;

