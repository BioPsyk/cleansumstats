#make all variables bash variables
dbfuncs=$1
dbrun=$2
mfile=$3
study_id=$4
revision_id=$5
raw_sumstat_id=$6
cleaned_sumstat_id=$7
raw_sumstat_checksum=$8
cleaned_sumstat_checksum=$9

#load all dbconnect functions
source $dbfuncs


#load all dbconnect functions
if [ "${study_id}" == "missing" ]; then
  titleX="$(grep "^study_title=" $mfile)"
  study_title="$(echo "${titleX#*=}")"
  echo "Adding revision..." 1>&2
  echo -e "${dbrun}\n${study_title}" 1>&2
  study_id="$(echo -e "${dbrun}\n${study_title}" | add_study)"
else
  study_title="$(echo -e "${dbrun}\n${study_id}" | exists_study_id)"
fi

if [ "${revision_id}" == "missing" ]; then
  titleX="$(grep "^study_title=" $mfile)"
  revision_title="$(echo "${titleX#*=}")"
  refX="$(grep "^study_reference=" $mfile)"
  revision_reference="$(echo "${refX#*=}")"
  dateX="$(grep "^study_date=" $mfile)"
  revision_date="$(echo "${dateX#*=}")"
  echo "Adding revision..." 1>&2
  echo -e "${dbrun}\n${study_id}\n${revision_title}\n${revision_reference}\n${revision_date}" 1>&2
  revision_id="$(echo -e "${dbrun}\n${study_id}\n${revision_title}\n${revision_reference}\n${revision_date}" | add_revision)"
else
  revision_title="$(echo -e "${dbrun}\n${revision_id}" | exists_revision_id)"
fi

if [ "${raw_sumstat_id}" == "missing" ]; then
  rawpX="$(grep "^path_sumStats=" $mfile)"
  raw_sumstat_filename="$(echo "${rawpX#*=}")"
  echo "Adding raw sumstat" 1>&2
  echo -e "${dbrun}\n${revision_id}\n${raw_sumstat_filename}\n${raw_sumstat_checksum}" 1>&2
  raw_sumstat_id="$(echo -e "${dbrun}\n${revision_id}\n${raw_sumstat_filename}\n${raw_sumstat_checksum}" | add_raw_sumstat)" 1>&2
else
  raw_sumstat_checksum="$(echo -e "${dbrun}\n${raw_sumstat_id}" | exists_sumstat_id)"
fi

if [ "${cleaned_sumstat_id}" == "missing" ]; then
  versionX="$(grep "^cleansumstats_version=" $mfile)"
  pipeline_version="$(echo "${versionX#*=}")"
  cleaned_sumstat_filename="cleaned_sumstat.gz"
  echo "Cleaned raw sumstat" 1>&2
  cleaned_sumstat_id="$(echo -e "${dbrun}\n${raw_sumstat_id}\n${pipeline_version}\n${cleaned_sumstat_filename}\n${cleaned_sumstat_checksum}" | add_cleaned_sumstat)" 1>&2
else
  cleaned_sumstat_checksum="$(echo -e "${dbrun}\n${cleaned_sumstat_id}" | exists_sumstat_id)"
fi

echo -e "study_id\t${study_id}"
echo -e "revision_id\t${revision_id}"
echo -e "raw_sumstat_id\t${raw_sumstat_id}"
echo -e "cleaned_sumstat_id\t${cleaned_sumstat_id}"

# If an ID is reused, then we should reuse all associated metadata (which needs to be extracted from the database)
echo -e "study_title\t${study_title}"
echo -e "revision_title\t${revision_title}"
echo -e "revision_reference\t${revision_reference}"
echo -e "revision_date\t${revision_date}"
echo -e "raw_sumstat_filename\t${raw_sumstat_filename}"
echo -e "raw_sumstat_checksum\t${raw_sumstat_checksum}"
echo -e "cleaned_sumstat_filename\t${cleaned_sumstat_filename}"
echo -e "cleaned_sumstat_checksum\t${cleaned_sumstat_checksum}"
echo -e "pipeline_version\t${pipeline_version}"


