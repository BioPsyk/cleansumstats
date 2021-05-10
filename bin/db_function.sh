#This script contains functions called from the main script

###############
# Does exist
###############
function exists_study_id {
read -r dbrun
read -r study_id
cat <<EOF | ${dbrun} sql
.headers off
SELECT original_title
  FROM gwa_studies
WHERE id == ${study_id}
EOF
}

function exists_revision_id {
read -r dbrun
read -r revision_id
cat <<EOF | ${dbrun} sql
.headers off
SELECT title
  FROM gwa_revisions
WHERE id == ${revision_id}
EOF
}

function exists_raw_sumstat_id {
read -r dbrun
read -r sumstat_id
cat <<EOF | ${dbrun} sql
.headers off
SELECT file_checksum
  FROM gwa_raw_sumstats
WHERE id == ${sumstat_id}
EOF
}

function exists_cleaned_sumstat_id {
read -r dbrun
read -r sumstat_id
cat <<EOF | ${dbrun} sql
.headers off
SELECT file_checksum
  FROM gwa_cleaned_sumstats
WHERE id == ${sumstat_id}
EOF
}

###############
# Add study
###############
function add_study {
read -r dbrun
read -r study_title
study_id=$(cat <<EOF | ${dbrun} sql
INSERT
  INTO gwa_studies (original_title)
VALUES ('${study_title}');
.headers off
SELECT last_insert_rowid();
EOF
)
echo "${study_id}"
}

###############
# Add revision
###############
function add_revision {

#read the variables line by line
read -r dbrun
read -r study_id
read -r revision_title
read -r revision_reference
read -r revision_date

revision_id=$(cat <<EOF | ${dbrun} sql
BEGIN TRANSACTION;
INSERT
  INTO gwa_revisions (study_id, title, external_reference, published_at)
VALUES ( '${study_id}'
       , '${revision_title}'
       , '${revision_reference}'
       , '${revision_date}'
       );
.headers off
SELECT last_insert_rowid();
COMMIT;
EOF
)
echo "${revision_id}"
}

###############
# Add raw sumstat
###############
function add_raw_sumstat {
#read the variables line by line
read -r dbrun
read -r revision_id
read -r raw_sumstat_filename
read -r raw_sumstat_checksum

raw_sumstat_id=$(cat <<EOF  | ${dbrun} sql
BEGIN TRANSACTION;
INSERT
  INTO gwa_raw_sumstats (revision_id, file_name, file_checksum)
VALUES ( '${revision_id}'
       , '${raw_sumstat_filename}'
       , '${raw_sumstat_checksum}'
       );
.headers off
SELECT last_insert_rowid();
COMMIT;
EOF
)


echo "${raw_sumstat_id}"
}
###############
# Add cleaned sumstat
###############
function add_cleaned_sumstat {
#read the variables line by line
read -r dbrun
read -r raw_sumstat_id
read -r pipeline_version
read -r clean_sumstat_filename
read -r clean_sumstat_checksum
clean_sumstat_id=$(cat <<EOF | ${dbrun} sql
BEGIN TRANSACTION;
INSERT
  INTO gwa_cleaned_sumstats (raw_sumstat_id, pipeline_version, file_name, file_checksum)
VALUES ( '${raw_sumstat_id}'
       , '${pipeline_version}'
       , '${clean_sumstat_filename}'
       , '${clean_sumstat_checksum}'
       );
.headers off
SELECT last_insert_rowid();
COMMIT;
EOF
)
echo "${clean_sumstat_id}"
}



