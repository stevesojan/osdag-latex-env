#!/bin/sh
# $Id: texconfig.sh 71679 2024-07-01 17:04:58Z karl $
# texconfig version 3.0
# Originally written by Thomas Esser. Public domain.
# Now maintained as part of TeX Live; correspondence to tex-live@tug.org.

# invoke the right shell:

test -f /bin/ksh && test -z "$RUNNING_KSH" \
  && { UNAMES=`uname -s`; test "x$UNAMES" = xULTRIX; } 2>/dev/null \
  && { RUNNING_KSH=true; export RUNNING_KSH; exec /bin/ksh $0 ${1+"$@"}; }
unset RUNNING_KSH

test -f /bin/bsh && test -z "$RUNNING_BSH" \
  && { UNAMES=`uname -s`; test "x$UNAMES" = xAIX; } 2>/dev/null \
  && { RUNNING_BSH=true; export RUNNING_BSH; exec /bin/bsh $0 ${1+"$@"}; }
unset RUNNING_BSH

# hack around a bug in zsh:
test -n "${ZSH_VERSION+set}" && alias -g '${1+"$@"}'='"$@"'

# preferentially use subprograms from our own directory.
mydir=`echo "$0" | sed 's,/[^/]*$,,'`
mydir=`cd "$mydir" && pwd`
PATH="$mydir:$PATH"; export PATH

# initializations...
progname=texconfig

# the version string
version='$Id: texconfig.sh 71679 2024-07-01 17:04:58Z karl $'

envVars="
  AFMFONTS BIBINPUTS BSTINPUTS CMAPFONTS CWEBINPUTS ENCFONTS GFFONTS
  GLYPHFONTS INDEXSTYLE LIGFONTS MFBASES MFINPUTS MFPOOL MFTINPUTS
  MISCFONTS MPINPUTS MPMEMS MPPOOL MPSUPPORT OCPINPUTS OFMFONTS
  OPENTYPEFONTS OPLFONTS OTPINPUTS OVFFONTS OVPFONTS PDFTEXCONFIG PKFONTS
  PSHEADERS SFDFONTS T1FONTS T1INPUTS T42FONTS TEXBIB TEXCONFIG TEXDOCS
  TEXFONTMAPS TEXFONTS TEXFORMATS TEXINDEXSTYLE TEXINPUTS TEXMFCNF
  TEXMFDBS TEXMFINI TEXMFSCRIPTS TEXPICTS TEXPKS TEXPOOL TEXPSHEADERS
  TEXSOURCES TFMFONTS TRFONTS TTFONTS VFFONTS WEB2C WEBINPUTS
"
tmpdir=${TMPDIR-${TEMP-${TMP-/tmp}}}/tctmp.$$
needsCleanup=false
lastUpdatedFile=

# 
###############################################################################
# setupFMT(void) - find a suitable version of fmt / adjust
#
setupFMT()
{
  case $FMT in
    "") 
      FMT=fmt
      test ! -x /bin/fmt && test ! -f /usr/bin/fmt &&
        { test -x /bin/adjust || test -x /usr/bin/adjust; } && FMT=adjust
      ;;
    *)
      return
      ;;
  esac
}

###############################################################################
# myFmt(args) - run $FMT
#
myFmt()
{
  setupFMT
  $FMT ${1+"$@"}
}

###############################################################################
# echoShowVariable(args ...)
#   show environment variables which names are as args and their values
#
echoShowVariable()
{
  for esv
  do
    var=$esv
    eval val=\"\${$var+=}\${$var- is unset}\"
    echo "$var$val"
  done | grep -v 'is unset$'
}

###############################################################################
# echoShowKpseVariable(args ...)
#   show kpathsea variables which names are as args and their values
#
echoShowKpseVariable()
{
  for eskv
  do
    var=$eskv
    val=`kpsewhich -var-value="$eskv"`
    echo "$var=$val"
  done
}

###############################################################################
# echoLocateBinary(args ...) - show where programs actually exist
#
echoLocateBinary()
{
  for elb
  do
    elbLoc=`checkForBinary "$elb"`
    if test -n "$ELB_PATH_ONLY"; then
      test -n "$elbLoc" && echo "$elbLoc"
    else
      case $elbLoc in
        "") echo "$elb: not found";;
        *) echo "$elb: $elbLoc";;
      esac
    fi
  done
}

###############################################################################
# echoLocateCfgfile(args ...) - show where files actually exist
#
echoLocateCfgfile()
{
  for elc
  do
    case $elc in
      texmf.cnf) elcLoc=`kpsewhich $elc`;;
      *) elcLoc=`tcfmgr --cmd find --file "$elc"`;;
    esac
    case $elcLoc in
      "") echo "$elc: not found";;
      *)  echo "$elcLoc";;
    esac
  done
}

###############################################################################
# checkForBinary(prog) - echo full path of prog
#
checkForBinary()
{
  cfbBinary=$1

  OLDIFS=$IFS
  IFS=:
  set x `echo "$PATH" | sed 's/^:/.:/; s/:$/:./; s/::/:.:/g'`; shift
  found=false
  for pathElem
  do
    case $pathElem in
      "") continue;;
      *) test -f "$pathElem/$cfbBinary" && { echo "$pathElem/$cfbBinary"; found=true; break; }
    esac
  done
  IFS=$OLDIFS
  case $found in
    true) (exit 0); return 0;;
    false) (exit 1); return 1;;
  esac
}

###############################################################################
# cleanup() - clean up the temp area and exit with proper exit status
#
cleanup()
{
  rc=$1
  $needsCleanup && test -n "$tmpdir" && test -d "$tmpdir" \
    && { cd / && rm -rf "$tmpdir"; }
  (exit $rc); exit $rc
}

###############################################################################
# setupTmpDir() - set up a temp directory and a trap to remove it
#
setupTmpDir()
{
  case $needsCleanup in
    true) return;;
  esac

  trap 'cleanup 1' 1 2 3 7 13 15
  needsCleanup=true
  (umask 077; mkdir "$tmpdir") \
    || abort "could not create directory \`$tmpdir'"
}

###############################################################################
# setupTexmfroot() - get value for MT_TEXMFROOT (with caching)
#
setupTexmfroot()
{
  case $MT_TEXMFROOT in
    "") MT_TEXMFROOT=`kpsewhich -var-value=TEXMFROOT`;;
    *) return;;
  esac
}


###############################################################################
# setupTexmfmain() - get value for MT_TEXMFMAIN (with caching)
#
setupTexmfmain()
{
  case $MT_TEXMFMAIN in
    "") MT_TEXMFMAIN=`kpsewhich -var-value=TEXMFMAIN`;;
    *) return;;
  esac
}

###############################################################################
# setupTexmfmain() - get value for MT_TEXMFDIST (with caching)
#
setupTexmfdist()
{
  case $MT_TEXMFDIST in
    "") MT_TEXMFDIST=`kpsewhich -var-value=TEXMFDIST`;;
    *) return;;
  esac
}

###############################################################################
# setupTexmfvar() - get value for MT_TEXMFVAR (with caching)
#
setupTexmfvar()
{
  case $MT_TEXMVAR in
    "") MT_TEXMVAR=`kpsewhich -var-value=TEXMFVAR`;;
    *) return;;
  esac
}

###############################################################################
# setupSystexmf() - get value for MT_SYSTEXMF (with caching)
#
setupSystexmf()
{
  case $MT_SYSTEXMF in
    "") MT_SYSTEXMF=`kpsewhich -var-value=SYSTEXMF`;;
    *) return;;
  esac
}

###############################################################################
# abort(errmsg)
#   print `errmsg' to stderr and exit with error code 1
#
abort()
{
  echo "$progname: $1." >&2
  cleanup 1
}

###############################################################################
# mktexdir(args)
#   call mktexdir script, disable all features (to prevent sticky directories)
#
mktexdir()
{
  setupTexmfmain
  MT_FEATURES=none "$MT_TEXMFMAIN/web2c/mktexdir" "$@" >&2
}

###############################################################################
# tcfmgr(args) - call tcfmgr script
#
tcfmgr()
{
  setupTexmfmain
  "$MT_TEXMFMAIN/texconfig/tcfmgr" "$@"
}

###############################################################################
# mktexupd(args) - call mktexupd script
#
mktexupd()
{
  setupTexmfmain
  "$MT_TEXMFMAIN/web2c/mktexupd" "$@"
}

###############################################################################
# getRelDir(file)
#   matches file against SYSTEXMF. Returns relative directory of file within
#   a texmf tree in variable relPart.
#
getRelDir()
{
  file=$1
  relPart=

  setupSystexmf
  OLDIFS=$IFS
  IFS='
'
  set x `echo "$MT_SYSTEXMF" | tr : '
'`; shift
  IFS=$OLDIFS

  # now loop over all components of SYSTEXMF
  for dir
  do
    test -n "$dir" || continue
    case "$file" in
      $dir/*)
        relPart=`echo "$file" | sed "s%$dir/*%%"`
        break
        ;;
    esac
  done

  # now check for success / failure
  case $relPart in
    ""|$file)
      # empty or full filename -> getRelDir failed!
      (exit 1); return 1
      ;;
    *)
      # relPart should just have the "dirname" part:
      relPart=`echo "$relPart" | sed 's%/*[^/]*$%%'`
      (exit 0); return 0
      ;;
  esac
}

###############################################################################
# configReplace(file pattern line)
#   The first line in file that matches pattern gets replaced by line.
#   line will be added at the end of the file if pattern does not match.
#
configReplace()
{
  configReplaceFile=$1; configReplacePat=$2; configReplaceLine=$3

  if grep "$configReplacePat" "$configReplaceFile" >/dev/null; then
    ed "$configReplaceFile" >/dev/null 2>&1 <<-eof
	/$configReplacePat/c
	$configReplaceLine
	.
	w
	q
eof
  else
    echo "$configReplaceLine" >> $configReplaceFile
  fi
}

###############################################################################
# fmgrConfigReplace (file regex value)
#   replaces line matching regex by value in file
#
fmgrConfigReplace()
{
  fmgrConfigReplaceChanged=false

  moreArgs=""
  while
    case $1 in
      --*) moreArgs="$moreArgs $1 $2";;
      *) break;;
    esac
  do shift; shift; done
  fmgrConfigReplaceFile=$1
  fmgrConfigReplaceRegex=$2
  fmgrConfigReplaceValue=$3

  setupTmpDir
  co=`tcfmgr $moreArgs --tmp $tmpdir --cmd co --file $fmgrConfigReplaceFile`
  if test $? != 0; then
    echo "$progname: fmgrConfigReplace co failed for \`$fmgrConfigReplaceFile'" >&2
    (exit 1); return 1
  fi
  set x $co; shift
  fmgrConfigReplaceID=$1; fmgrConfigReplaceCfgFile=$3; fmgrConfigReplaceOrigFile=$4
  configReplace "$fmgrConfigReplaceCfgFile" "$fmgrConfigReplaceRegex" "$fmgrConfigReplaceValue"
  ci=`tcfmgr --tmp $tmpdir --cmd ci --id "$fmgrConfigReplaceID"`
  if test $? != 0; then
    echo "$progname: fmgrConfigReplace ci failed for \`$fmgrConfigReplaceFile'" >&2
    (exit 1); return 1
  fi
  case $ci in
    "") :;;
    $lastUpdatedFile)
      fmgrConfigReplaceChanged=true;;
    *) echo "$progname: updated configuration saved as file \`$ci'" >&2
       fmgrConfigReplaceChanged=true
       lastUpdatedFile=$ci;;
  esac
  (exit 0); return 0
}

###############################################################################
# setupModesMfFile(void) - find modes.mf file (with caching)
#
setupModesMfFile()
{
  case $modesMfFile in
    "")
      modesMfFile=`tcfmgr --cmd find --file modes.mf`
      ;;
    *)
      return
      ;;
  esac
}

###############################################################################
# locateConfigPsFile(void) - find config.ps file (with caching)
#
locateConfigPsFile()
{
  case $configPsFile in
    "")
      configPsFile=`tcfmgr --cmd find --file config.ps`
      ;;
    *)
      return
      ;;
  esac
}

###############################################################################
# listMfModes(file) - list modes from modes.mf file
#
listMfModes()
{
  grep mode_def "$modesMfFile" |
  sed -e "s/mode_def //" \
      -e "s/ .*%[^ ]* / '/" \
      -e "s/\$/' /" |
  egrep -v "^(help|%)" | sort
}

###############################################################################
# listDvipsPapers(void) - list paper definitions from config.ps
#
listDvipsPapers()
{
  grep '@ ' $configPsFile | sed "s/..//;s/ / '/;s/\$/' /"
}

###############################################################################
# getFormatsForHyphen(void)
#   list all formats which have customizable hyphenation
#
getFormatsForHyphen()
{
  fmtutil --catcfg | awk '$3 != "-" {print $1}' | sort
}

###############################################################################
# getRes(mode) - print resolution (both X and Y axis) to metafont mode
#
getRes()
{
  getResMode=$1
  (
    cd $tmpdir
    cat >mftmp.mf <<-'eof'
	let myexit = primitive_end_;
	mode_setup;
	string xdpi;
	xdpi := decimal round pixels_per_inch;
	message "XDPI = " & xdpi;
	string ydpi;
	ydpi := decimal round (pixels_per_inch * aspect_ratio);
	message "YDPI = " & ydpi;
	fontmaking := 0;
	myexit;
eof
    mf '\mode='"$getResMode"';  \input ./mftmp' </dev/null \
     | awk '$1 == "XDPI" || $1 == "YDPI" { print $3 }'
  )
}

###############################################################################
# checkElemInList(elem, list)
#   check if element exists in list
###############################################################################
checkElemInList()
{
  checkElemInListElem=$1; shift
  checkElemInListFound=false
  for checkElemInListIter
  do
    case "x$checkElemInListElem" in
      x$checkElemInListIter)
        checkElemInListFound=true
        break
        ;;
    esac
  done
  case $checkElemInListFound in
    true) (exit 0); return 0;;
  esac
  (exit 1); return 1
}


# show version information from the distribution, if we have any.
showDistVersionInfo()
{
  # TeX Live file.
  setupTexmfroot
  test -f $MT_TEXMFROOT/release-texlive.txt \
  && sed 1q $MT_TEXMFROOT/release-texlive.txt

  # no harm in continuing to look for the teTeX files.
  test -f $MT_TEXMFMAIN/release-tetex-src.txt \
  && "teTeX-src release:   `cat $MT_TEXMFMAIN/release-tetex-src.txt`"
  test -f $MT_TEXMFDIST/release-tetex-texmf.txt \
  && "teTeX-texmf release: `cat $MT_TEXMFDIST/release-tetex-texmf.txt`"
}

# 
###############################################################################
# tcBatch(args)
#   handle batch mode
###############################################################################
tcBatch()
{
  help="texconfig supports adjusting and updating many aspects of
the TeX installation.

Usage: $progname conf                  (show configuration information)
       $progname dvips [OPTION...]     (dvips options)
       $progname faq                   (show pointer to TeX Live docs)
       $progname findprog PROG...      (show locations of PROGs, a la which)
       $progname font vardir DIR
       $progname font ro
       $progname font rw
       $progname formats               (edit fmtutil.cnf)
       $progname help                  (or --help; show this help)
       $progname hyphen FORMAT         (edit hyphenation config for FORMAT)
       $progname init [FORMAT]...      (rebuild FORMATs, or all formats
                                        plus run texlinks and updmap)
       $progname mode MODE             (set Metafont MODE)
       $progname pdftex [OPTION]...    (pdftex options)
       $progname rehash                (rebuild ls-R files with mktexlsr)
       $progname version               (or --version; show version info)

Get more help with:
       $progname dvipdfmx
       $progname dvips
       $progname font
       $progname hyphen
       $progname mode
       $progname pdftex
       $progname xdvi

Report bugs to: tex-k@tug.org
TeX Live home page: <http://tug.org/texlive/>
"

  case $1 in
    # texconfig conf
    conf|confall)
      setupTexmfmain
      setupTexmfdist
      echo '=========================== version information =========================='
      showDistVersionInfo
      echo
      echo '==================== binaries found by searching $PATH ==================='
      echo "PATH=$PATH"
      echoLocateBinary kpsewhich updmap fmtutil texconfig tex pdftex mktexpk dvips dvipdfmx
      echo
      echo '=========================== active config files =========================='
      echoLocateCfgfile texmf.cnf updmap.cfg fmtutil.cnf config.ps mktex.cnf XDvi pdftexconfig.tex | sort -k 2
      echo
      echo '============================= font map files ============================='
      for m in psfonts.map pdftex.map ps2pk.map; do
        echo "$m: `kpsewhich $m`"
      done
      echo
      echo '=========================== kpathsea variables ==========================='
      echoShowKpseVariable TEXMFMAIN TEXMFDIST TEXMFLOCAL TEXMFSYSVAR TEXMFSYSCONFIG TEXMFVAR TEXMFCONFIG TEXMFHOME VARTEXFONTS TEXMF SYSTEXMF TEXMFDBS WEB2C TEXPSHEADERS TEXCONFIG ENCFONTS TEXFONTMAPS

      echo
      echo '==== kpathsea variables from environment only (ok if no output here) ===='
      echoShowVariable $envVars
      ;;

    # texconfig dvipdfmx
    dvipdfmx)
      abort "Use tlmgr paper dvipdfmx"
      rc=1
      ;;

    # texconfig dvips
    dvips)
      shift
      help="Usage: $progname dvips add PRINTER
       $progname dvips del PRINTER
       $progname dvips [-P PRINTER] mode MODE
       $progname dvips [-P PRINTER] offset OFFSET
       $progname dvips [-P PRINTER] printcmd CMD"
      case $1 in
        -P)
          case $2 in
            "")
              echo "$progname: missing arg for parameter -P" >&2
              rc=1; (exit $rc); return $rc
              ;;
            *)
              otherPrinter=true
              otherPrinterName=$2
              otherPrinterFile=`kpsewhich -format='dvips config' "config.$otherPrinterName"`
              case $otherPrinterFile in
                "")
                  echo "$progname: configuration file \`config.$otherPrinterName' for printer \`$otherPrinterName' not found" >&2
                  rc=1; (exit $rc); return $rc
                  ;;
                *) shift; shift;;
              esac
              ;;
          esac
          ;;
        *)
          otherPrinter=false
          ;;
      esac
      case $otherPrinter in
        true)
          tcBatchDvipsPrinter=$otherPrinterName
          moreFmgrArgs="--reldir dvips/config --infile $otherPrinterFile"
          ;;
        *)
          tcBatchDvipsPrinter=ps
          ;;
      esac
      case $1 in
        add)
          case $2 in
            "")
              echo "Usage: $progname dvips add PRINTER" >&2
              rc=1
              ;;
            *)
              printerName=$2
              pFile=`kpsewhich -format='dvips config' "config.$printerName"`
              case $pFile in
                "")
                  setupTmpDir
                  tcfRet=`tcfmgr --emptyinfile --reldir dvips/config --cmd co --tmp $tmpdir --file "config.$printerName"`
                  if test $? != 0; then
                    echo "$progname: failed to add new configuration file \`config.$printerName'" >&2
                    rc=1
                  else
                    set x $tcfRet; shift
                    tcBatchDvipsAddID=$1; tcBatchDvipsAddFile=$3
                    echo "% file config.$printerName; added by texconfig" > "$tcBatchDvipsAddFile"
                    tcfRet=`tcfmgr --tmp $tmpdir --id "$tcBatchDvipsAddID" --cmd ci`
                    if test $? != 0; then
                      echo "$progname: failed to add new configuration file \`config.$printerName'" >&2
                      rc=1
                    else
                      echo "$progname: file $tcfRet added" >&2
                    fi
                  fi
                  ;;
                *)
                  echo "$progname: configuration file for printer \`$printerName' already exists (\`$pFile')" >&2
                  rc=1
                  ;;
              esac
              ;;
          esac
          ;;
        del)
          case $2 in
            "")
              echo "Usage: $progname dvips del PRINTER" >&2
              rc=1
              ;;
            *)
              printerName=$2
              pFile=`kpsewhich -format='dvips config' "config.$printerName"`
              case $pFile in
                "")
                  echo "$progname: configuration file for printer \`$printerName' (config.$printerName) not found" >&2
                  rc=1
                  ;;
                *)
                  if rm "$pFile"; then
                    echo "$progname: file \`$pFile' removed" >&2
                  else
                    echo "$progname: failed to remove file \`$pFile'" >&2
                    rc=1
                  fi
                  ;;
              esac
              ;;  
          esac
          ;;
        paper-list)
          locateConfigPsFile
          listDvipsPapers
          ;;
        paper)
          abort "Use tlmgr paper dvips"
          ;;
        mode)
          case $2 in
            "")
              echo "Usage: $progname dvips mode MODE

Valid MODE settings:"
              setupModesMfFile
              listMfModes | sed 's@ .*@@; s@^@  @' | myFmt
              rc=1
              ;;
            *)
              tcBatchDvipsMode=$2
              setupTmpDir
              setupModesMfFile
              if checkElemInList "$tcBatchDvipsMode" `listMfModes | sed 's@ .*@@'`; then
                set x `getRes "$tcBatchDvipsMode"`; shift
                resX=$1; resY=$2
                fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^M' "M $tcBatchDvipsMode"
                fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^D' "D $resX"
                fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^X' "X $resX"
                fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^Y' "Y $resY"
              else
                echo "$progname: unknown MODE \`$tcBatchDvipsMode' given as argument for \`$progname dvips mode'" >&2
                echo "$progname: try \`$progname dvips mode' for help" >&2
                rc=1
              fi
              ;;
          esac
          ;;
        offset)
          offset=$2
          case $offset in
            "")
              echo "Usage: $progname dvips offset OFFSET"
              rc=1
              ;;
            *)
              fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^O' "O $offset"
          esac
          ;;
        printcmd)
          printcmd=$2
          case $printcmd in
            "")
              echo "Usage: $progname dvips printcmd CMD"
              rc=1
              ;;
            -)
              fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^o' o
              ;;
            *)
              fmgrConfigReplace $moreFmgrArgs config.$tcBatchDvipsPrinter '^o' "o |$printcmd"
              ;;
          esac
          ;;
        "")
          echo "$help" >&2; rc=1
          ;;
        *)
          echo "$progname: unknown option \`$1' given as argument for \`$progname dvips'" >&2
          echo "$progname: try \`$progname dvips' for help" >&2
          rc=1
          ;;
      esac
      ;;

    faq)
      echo "Please see https://tug.org/texlive/doc/ for the documentation"
      echo "available in TeX Live."
      ;;

    findprog)
      shift
      ELB_PATH_ONLY=1 echoLocateBinary "$@"
      ;;

    # handle "texconfig font"
    font)
      setupTexmfroot
      help="Usage: $progname font vardir DIR
       $progname font ro
       $progname font rw

The vardir option changes the VARTEXFONTS variable in the texmf.cnf file.

The rw option makes the VARTEXFONTS directory (and subtrees pk, tfm,
source) world writable and sets the features appendonlydir:varfonts
in mktex.cnf.

The ro option makes the VARTEXFONTS directory (and subtrees pk, tfm,
source) writable for the owner only and sets the feature texmfvar in
mktex.cnf.

For more information about these \`features', consult the teTeX manual
(e.g. by running \`texdoc TETEXDOC')."

      case $2 in
        vardir)
          case $3 in
            "")
              echo "$help" >&2
              rc=1
              ;;
            *)
              tcBatchFontVardir=$3
              # tfc=`kpsewhich texmf.cnf`
              tfc="$MT_TEXMFROOT/texmf.cnf"
              touch "$tfc"
              if test -n "$tfc"; then
                if test -w "$tfc"; then
                  configReplace "$tfc" '^VARTEXFONTS' "VARTEXFONTS  = $tcBatchFontVardir"
                else
                  echo "$progname: setting up vardir failed. Reason: no permission to write file \`$tfc'" >&2
                  rc=1
                fi
              else
                echo "$progname: setting up vardir failed. Reason: failed to find file texmf.cnf" >&2
                rc=1
              fi
              ;;
          esac
          ;;
        rw)
          MT_VARTEXFONTS=`kpsewhich -var-value VARTEXFONTS`
          if test -z "$MT_VARTEXFONTS"; then
            echo "$progname: failed to set \`font rw'; reason: could not determine VARTEXFONTS variable." >&2; rc=1
            return
          fi
          test -d "$MT_VARTEXFONTS" || mktexdir "$MT_VARTEXFONTS"
          if test ! -d "$MT_VARTEXFONTS"; then
            echo "$progname: failed to set \`font rw'; reason: directory \`$MT_VARTEXFONTS' does not exist." >&2; rc=1
            return
          fi
          chmod 1777 "$MT_VARTEXFONTS" || {
            echo "$progname: failed to modify permissions in \`$MT_VARTEXFONTS'." >&2; rc=1
            return;
          }
          (
            cd "$MT_VARTEXFONTS" || exit
            echo "$progname: modifying permissions in \`$MT_VARTEXFONTS' ..." >&2
            for d in pk tfm source; do
              test -d "$d" && find $d -type d -exec chmod 1777 '{}' \;
            done
            echo "$progname: all permissions set." >&2
          )
          setupTmpDir
          fmgrConfigReplace mktex.cnf '^: ..MT_FEATURES=' ": \${MT_FEATURES=appendonlydir:varfonts}"
          ;;
        ro)
          MT_VARTEXFONTS=`kpsewhich -var-value VARTEXFONTS`
          if test -z "$MT_VARTEXFONTS"; then
            echo "$progname: failed to set \`font ro'; reason: could not determine VARTEXFONTS variable." >&2; rc=1
            return
          fi
          test -d "$MT_VARTEXFONTS" || mktexdir "$MT_VARTEXFONTS"
          if test ! -d "$MT_VARTEXFONTS"; then
            echo "$progname: failed to set \`font ro'; reason: directory \`$MT_VARTEXFONTS' does not exist." >&2; rc=1
            return
          fi
          chmod 755 "$MT_VARTEXFONTS" || {
            echo "$progname: failed to modify permissions in \`$MT_VARTEXFONTS'." >&2; rc=1
            return;
          }
          (
            cd "$MT_VARTEXFONTS" || exit
            echo "$progname: modifying permissions in \`$MT_VARTEXFONTS' ..." >&2
            for d in pk tfm source; do
              test -d "$d" && find "$d" -type d -exec chmod 755 '{}' \;
            done
            echo "$progname: all permissions set." >&2
          )
          setupTmpDir
          fmgrConfigReplace mktex.cnf '^: ..MT_FEATURES=' ": \${MT_FEATURES=texmfvar}"
          ;;
        "") echo "$help" >&2; rc=1;;
        *) echo "$progname: unknown option \`$2' given as argument for \`$progname font'" >&2
           echo "$progname: try \`$progname font' for help" >&2
           rc=1
           ;;
      esac
      ;;

    formats)
      cat >&2 <<EOM
texconfig formats is no longer supported, because manual edits of
fmtutil.cnf will be overwritten by the new TeX Live package manager,
tlmgr, which regenerates that file as needed upon package changes.
Thus, to add or remove formats, the recommended method is to use tlmgr
to add or remove the appropriate package.

If you need to make manual additions, you can edit the file
fmtutil-local.cnf under TEXMFLOCAL.  Further information with
tlmgr --help and at http://tug.org/texlive/tlmgr.html.

Exiting.
EOM
      exit 1  # but leave the real code for posterity

      setupTmpDir
      echo "$progname: analyzing old configuration..." >&2
      fmtutil --catcfg > $tmpdir/pre
      fmtutil --edit
      echo "$progname: analyzing new configuration..." >&2
      fmtutil --catcfg > $tmpdir/post

      if cmp $tmpdir/pre $tmpdir/post >/dev/null 2>&1; then
        echo "$progname: no new/updated formats available ..." >&2
      else
      echo "$progname: updating formats ..." >&2
        comm -13 $tmpdir/pre $tmpdir/post > $tmpdir/addOrChange
        for i in `awk '{print $1}' $tmpdir/addOrChange`; do
          fmtutil --byfmt "$i" || rc=1
        done
        texlinks --multiplatform || rc=1
      fi
      ;;

    help|--help|-h)
      echo "$help"
      ;;

    # "hyphen FORMAT"
    hyphen)
      cat >&2 <<EOM
texconfig hyphen is no longer supported, because manual edits of
language.dat (or language.def) will be overwritten by the new TeX Live
package manager, tlmgr, which regenerates those configuration files as
needed upon package changes.  Thus, to add or remove hyphenation
patterns, the recommended method is to use tlmgr to add or remove the
appropriate package.

If you need to make manual additions, you can edit the files
language-local.dat and language-local.def under TEXMFLOCAL.  Further
information with tlmgr --help and at http://tug.org/texlive/tlmgr.html.

Exiting.
EOM
      exit 1  # but leave the real code for posterity

      tcBatchHyphenFormat=$2
      formatsForHyphen=`getFormatsForHyphen`
      formatsForHyphenFmt=`echo "$formatsForHyphen" | myFmt | sed 's@^@  @'`
      help="Usage: $progname hyphen FORMAT

Valid FORMATs are:
$formatsForHyphenFmt"
      case $tcBatchHyphenFormat in
        "")
          echo "$help" >&2; rc=1
          ;;
        *)
          if checkElemInList "$tcBatchHyphenFormat" $formatsForHyphen; then

            tcBatchHyphenFile=`fmtutil --showhyphen "$tcBatchHyphenFormat"`
            case $tcBatchHyphenFile in
              "")
                echo "$progname: could not find hyphen setup file for format \`$tcBatchHyphenFormat'" >&2
                rc=1
                return
                ;;
            esac

            getRelDir "$tcBatchHyphenFile"
            case $relPart in
              "")
                # edit tcBatchHyphenFile directly
                tcBatchHFID=
                setupTmpDir
                tcBatchHFEdit=$tcBatchHyphenFile
                tcBatchHFOrig=$tmpdir/hforig
                cp "$tcBatchHyphenFile" "$tcBatchHFOrig"
                ;;
              *)
                # use tcfmgr
                tcBatchHyphenFileBasename=`echo "$tcBatchHyphenFile" | sed 's@.*/@@'`
                setupTmpDir
                co=`tcfmgr --tmp $tmpdir --cmd co --file "$tcBatchHyphenFileBasename" --reldir "$relPart" --infile "$tcBatchHyphenFile"`
                if test $? != 0; then
                  echo "$progname: failed to check out file \`$tcBatchHyphenFile'" >&2
                  rc=1
                  return 1
                else
                  set x $co; shift
                  tcBatchHFID=$1; tcBatchHFEdit=$3; tcBatchHFOrig=$4
                fi
                ;;
            esac
            ${VISUAL-${EDITOR-vi}} "$tcBatchHFEdit"
            if cmp "$tcBatchHFEdit" "$tcBatchHFOrig" >/dev/null 2>&1; then
              echo "$progname: configuration unchanged." >&2
            else
              case $tcBatchHFID in
                "")
                  tcBatchHFOut=$tcBatchHFEdit
                  echo "$progname: updated configuration saved as file \`$tcBatchHFOut'" >&2
                  lastUpdatedFile=$ci
                  ;;
                *)
                  ci=`tcfmgr --tmp $tmpdir --cmd ci --id "$tcBatchHFID"`
                  if test $? != 0; then
                    echo "$progname: failed to check in file \`$tcBatchHyphenFileBasename'" >&2
                    rc=1
                    return
                  else
                    tcBatchHFOut=$ci
                    echo "$progname: updated configuration saved as file \`$tcBatchHFOut'" >&2
                    lastUpdatedFile=$ci
                  fi
                  ;;
              esac
              fmtutil --byhyphen "$tcBatchHFOut"
            fi
          else
            echo "$progname: invalid format \`$tcBatchHyphenFormat' specified as argument for \`$progname hyphen'" >&2
            echo "$progname: for getting help, try \`$progname hyphen'" >&2
            rc=1
          fi
          ;;
      esac
      ;;

    hyphen-list)
      getFormatsForHyphen
      ;;

    init)
      case $2 in
        "")
          if fmtutil --all \
             && texlinks --multiplatform \
             && updmap; then
            :
          else
            rc=1
          fi
          ;;
        *)
          shift 1
          for i in "$@"; do
            fmtutil --byfmt "$i" || rc=1
          done
          ;;
      esac
      ;;

    mode-list)
      setupModesMfFile
      listMfModes
      ;;

    mode)
      case $2 in
        "")
          echo "Usage: $progname mode MODE

Valid MODE settings:"
          setupModesMfFile
          listMfModes | sed 's@ .*@@; s@^@  @' | myFmt
          rc=1
          ;;
        *)
          tcBatchMode=$2
          setupModesMfFile
          if checkElemInList $tcBatchMode `listMfModes | sed 's@ .*@@'`; then

            # modify mktex.cnf
            setupTmpDir
            fmgrConfigReplace mktex.cnf '^: ..MODE=' ": \${MODE=$tcBatchMode}"
            set x `getRes "$tcBatchMode"`; shift
            tcBatchRes=$1
            fmgrConfigReplace mktex.cnf '^: ..BDPI=' ": \${BDPI=$tcBatchRes}"

            if checkForBinary dvips >/dev/null && tcfmgr --cmd find --file config.ps >/dev/null 2>&1; then
              tcBatch dvips mode "$tcBatchMode"
            fi
            if checkForBinary pdftex >/dev/null && tcfmgr --cmd find --file pdftexconfig.tex >/dev/null 2>&1; then
              tcBatch pdftex mode "$tcBatchMode"
            fi
          else
            echo "$progname: unknown mode \`$tcBatchMode' specified as argument for \`$progname mode'" >&2; rc=1
          fi
          ;;
      esac
      ;;

    paper)
      abort "Use tlmgr paper"
      ;;

    pdftex)
      abort "Use tlmgr paper pdftex"
      ;;

    rehash)
      mktexlsr
      ;;
    
    # 
    version|--version)
      echo "$progname version $version"
      setupTexmfmain
      setupTexmfdist
      showDistVersionInfo
      (exit 0); exit 0;;

    # handle "xdvi paper PAPER"
    xdvi)
      abort "Use tlmgr paper xdvi"
      ;;
    *)
      echo "$progname: unknown option \`$1' given as argument for \`$progname'" >&2
      echo "$progname: try \`$progname help' for help" >&2
      rc=1
  esac
}

###############################################################################
# tcInteractive(void)
#   handle interactive mode
###############################################################################
tcInteractive()
{
  texconfig-dialog
}

###############################################################################
# main()
###############################################################################
rc=0
case $# in
  0) tcInteractive;;
  *) tcBatch "$@";;
esac

cleanup $rc
