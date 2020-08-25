################################################################################
#
# This is an awk script that attempts at inferring the column names for the 
# different important columns in a sumstat file.
# 
# It does so by first scanning trough the whole or a part of a file, trying to 
# classify all values on typical characteristics. Then each column is summarized
# in a table containing the proportion of all types for each column. From this
# information the table correspondings to each column is checked against the
# criterias to be choosen for markername,chr,pos, a1,a2 and pvalue
#
# The more columns the longer time it will take to scan through as all columns
# are scanned through one a the time for the table creation.
#
# More rows used for input the more accurate the pvalue inference will be, which
# is a little bit sensitive to small sets of sumstats as it relies on at least 
# one value being below 0.0001 (not including values like -1.23). The more 
# rows the better, but it will also take more time to process.
#
# A temporary directory is created based on the input name, this folder can be
# removed after the script has been finished.
#
# Output is written straight to the stdout
#
# Execution requires to arguments: 1) gzipped sumstat file 2) nr rows to use
#
################################################################################

#input sumstat file in gzip format
infile0=$1
nrows=$2

#create tmp dir and make an unzipped copy within
infilex="$(basename ${infile0})"
infilex="${infilex%.gz}"
infilex="${infilex%.txt}"
mkdir "tmp_${infilex}"
infile="tmp_${infilex}/tmp_${infilex}.txt"
zcat $infile0 | head -n ${nrows} > ${infile}

header=($(head -n1 $infile))

#investigate number of unique entries in each row 
#(this is a lazy loop over each column instead of processing them all at once, which is a bit hard)
nf="$(head $infile | awk 'NR==1{print NF}')"
for col in $(seq 1 1 ${nf}); do 
  #echo "$col"
  awk -vcol="${col}" '
  {seen[$col] += 1}
  END{printf "%s\t", length(seen)/NR}
  ' <( tail -n+2 $infile )
done | awk '{print $0}' > tmp_${infilex}/tmp1

#characterize each value in the original data
awk -vOFS="\t" '

function detect(x){
  #first remove any presence of chr, but only if chr detected
  gsub(/[c|C][h|H][r|R]/,"",x)
  x=tolower(x)

  #make comma values easier to parse by prepending a zero
  if(x ~ /^\.[[:digit:]]+/ ){
    x="0"x
  }
  if(x ~ /^.{1,2}[_|:][[:digit:]]+.*/){
    #Indicator of markername 
    ans="MA_MN"

  }else if(x ~ /^-*[[:digit:]]+.*[[:digit:]]*$/){
    #check if everything is recogized as a numeric 

    #make sure it is numeric (although screwing up some decimals as it adds "precision")
    CONVFMT="%.17g"
    x=x+0

    if(x ~ /\.[[:digit:]]+/){
        # Indicator of a decimal value (minus values will not pass by this check)
      if(x ~ /^[-]/){
        #Values starting with -
        ans="DEC_MINUS"
      }else if(x < 0.0000001){
        # Strong Indicator of a pvalue
        ans="DEC_LT00000001"
      }else if(x < 0.000001){
        ans="DEC_LT0000001"
      }else if(x < 0.00001){
        ans="DEC_LT000001"
      }else if(x < 0.0001){
        # Strong Indicator of a pvalue
        ans="DEC_LT00001"
      }else if(x < 0.001){
        # Indicator of a pvalue
        ans="DEC_LT0001"
      }else if(x < 0.01){
        # Indicator of a pvalue
        ans="DEC_LT001"
      }else if(x < 0.1){
        # Indicator of a pvalue
        ans="DEC_LT01"
      }else if(x < 0.2){
        # Indicator of a pvalue
        ans="DEC_LT02"
      }else if(x < 0.3){
        # Indicator of a pvalue
        ans="DEC_LT03"
      }else if(x < 0.4){
        # Indicator of a pvalue
        ans="DEC_LT04"
      }else if(x < 0.5){
        # Indicator of a pvalue
        ans="DEC_LT05"
      }else if(x < 0.6){
        # Indicator of a pvalue
        ans="DEC_LT06"
      }else if(x < 0.7){
        # Indicator of a pvalue
        ans="DEC_LT07"
      }else if(x < 0.8){
        # Indicator of a pvalue
        ans="DEC_LT08"
      }else if(x < 0.9){
        # Indicator of a pvalue
        ans="DEC_LT09"
      }else if(x < 1.0){
        # Indicator of a rsq or pvalue
        ans="DEC_LT1"
      }else{
        #Values not catched by these indicating other form of statistic
        ans="DEC_GT1"
      }
    #Here below only integers and other stuff, but no decimals
    }else if(x ~ /^[-]/){
      ans="DI_MINUS"
    }else if(x >= 1 && x <= 26){
      ans="CH_CHR"
    }else if(length(x) == 3){
      ans="DI_EQ3"
    }else if(length(x) == 4){
      ans="DI_EQ4"
    }else if(length(x) == 5){
      ans="DI_EQ5"
    }else if(length(x) == 6){
      ans="DI_EQ6"
    }else if(length(x) == 7){
      ans="DI_EQ7"
    }else if(length(x) == 8){
      ans="DI_EQ8"
    }else if(length(x) == 9){
      ans="DI_EQ9"
    }else if(length(x) == 10){
      ans="DI_EQ10"
    }else if(length(x) > 10){
      ans="DI_MORE10"
    }else{
      ans="WHAT_DI"
    }

  }else if(x ~ /^[x|y|m]$/){
    #Indicator of chromosomes position
    ans="CH_CHR"

  }else if(x ~ /^[a|t|g|c]+$/){
    #Indicator of allele 
    ans="AL_AL"

  }else if(x ~ /^["rs"]/){
    #Indicator of rsid 
    ans="MA_MN"

  }else{
    ans="WHAT_END"
  }
  return ans;
}

NR>1{for(k=1; k < NF; k++){
    val=detect($k)
    printf "%s%s", val, "\t"
  }
  val=detect($NF)
  printf "%s%s", val, "\n"
}

' $infile > tmp_${infilex}/tmp2


#show output
#cat tmp1 tmp2 | head -n5 | column -t

for col in $(seq 1 1 ${nf}); do 
  #echo "$col"
  awk -vcol="${col}" '
  {seen[$col] += 1}
  END{
    for (i in seen){ print seen[i]/NR, seen[i],i }
  }
  ' tmp_${infilex}/tmp2 > tmp_${infilex}/tmp_col_${col}
done

################
#classify each column based on the collected information
################

##MARKERNAME
markername="missing"
for col in $(seq 1 1 ${nf}); do 
  col_uniques="$(awk -vcol="${col}" '{print $col }' tmp_${infilex}/tmp1)"
  fi="tmp_${infilex}/tmp_col_${col}"
  
  #what do we need to guess markername?
  #required only one instance of MARKER_NAME (MA_MN)
  if grep -qF "MA_MN" ${fi}; then
    i=$((col-1))
    val="${header[$i]}"
    markername=${val}
  fi
done

#CHROMOSOME
chromosome="missing"
colu="missing"

for col in $(seq 1 1 ${nf}); do 
  col_uniques="$(awk -vcol="${col}" '{print $col }' tmp_${infilex}/tmp1)"
  fi="tmp_${infilex}/tmp_col_${col}"
  
  #what do we need to guess markername?
  #required more than 90% of instance of CH_CHR
  if grep -qF "CH_CHR" ${fi}; then
    perc="$(awk '$3 == "CH_CHR"{print $1}' $fi)"
    atest="$(echo "${perc}" | awk '{if($1 > 0.9){print "0"}else{print "1"}}')"
    if [ ${atest} == "0" ] ; then
      i=$((col-1))
      val="${header[$i]}"
      if [ "${chromosome}" == "missing" ]; then
        chromosome="${val}"
        colu="${col_uniques}"
      else
        utest="$(echo "${col_uniques}" | awk -vcolu2="${colu}" '{if($1 > colu2){print "0"}else{print "1"}}')"
        if [ ${utest} == "0" ] ; then
          chromosome="${val}"
          colu=${col_uniques}
        else
          :
        fi
      fi
    fi
  fi
done

#POSITION
position="missing"
for col in $(seq 1 1 ${nf}); do 
  col_uniques="$(awk -vcol="${col}" '{print $col }' tmp_${infilex}/tmp1)"
  fi="tmp_${infilex}/tmp_col_${col}"
  
  #what do we need to guess position?
  #required more than 90% of instance to be unique (multi-allelics and indels is a danger here)
  if grep -Pq "DI.*" ${fi}; then
    #require no decimals
    if grep -Pq "DEC_.*" ${fi}; then
      :
    else
      atest="$(echo "${col_uniques}" | awk '{if($1 > 0.9){print "0"}else{print "1"}}')"
      if [ ${atest} == "0" ] ; then
        i="$((col-1))"
        val="${header[$i]}"
        position="${val}"
      fi
    fi
  fi
done

#ALLELE
allele1="missing"
allele2="missing"
for col in $(seq 1 1 ${nf}); do 
  col_uniques="$(awk -vcol="${col}" '{print $col }' tmp_${infilex}/tmp1)"
  fi="tmp_${infilex}/tmp_col_${col}"
  
  #what do we need to guess allele?
  #required more than 90% of instance to be unique
  if grep -qF "AL_AL" ${fi}; then
    perc="$(awk '$3 == "AL_AL"{print $1}' $fi)"
    atest="$(echo "${perc}" | awk '{if($1 > 0.9){print "0"}else{print "1"}}')"
    if [ ${atest} == "0" ] ; then
      i=$((col-1))
      val="${header[$i]}"
      if [ "${allele1}" == "missing" ]; then
        allele1=${val}
      else
        allele2=${val}
      fi
    fi
  fi
done

#PVALUE
pvalue="missing"
for col in $(seq 1 1 ${nf}); do 
  col_uniques="$(awk -vcol="${col}" '{print $col }' tmp_${infilex}/tmp1)"
  fi="tmp_${infilex}/tmp_col_${col}"
  
  #what do we need to guess pvalue?
  #no value larger than 1
  #no values with minus
  if grep -qF "DEC_GT1" ${fi}; then
    :
  elif grep -qF "DEC_MINUS" ${fi}; then
    :
  elif grep -qF "DEC_LT00001" ${fi}; then
   #because some sumstats are pre-filtered on only significatnt p-values, then the distribution check doesnt really work
   # perc1="$(awk '$3 == "DEC_LT1"{print $1}' $fi)"
   # perc2="$(awk '$3 == "DEC_LT09"{print $1}' $fi)"
   # perc3="$(awk '$3 == "DEC_LT08"{print $1}' $fi)"
   # perc4="$(awk '$3 == "DEC_LT07"{print $1}' $fi)"
   # atest="$(echo "${perc1} ${perc2} ${perc3} ${perc4}" | awk '{if($1 > 0.05 && $2 > 0.05 && $3 > 0.05 && $4 > 0.05){print "0"}else{print "1"}}')"
   # if [ ${atest} == "0" ] ; then
      i=$((col-1))
      val="${header[$i]}"
      pvalue=${val}
   # fi
  else
    :
  fi
done


#output 
echo "col_SNP=$markername"
echo "col_CHR=$chromosome"
echo "col_POS=$position"
echo "col_EffectAllele=$allele1"
echo "col_OtherAllele=$allele2"
echo "col_P=$pvalue"







