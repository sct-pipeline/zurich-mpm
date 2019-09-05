#!/bin/bash
#
# Pipeline for MPM data.
#
# Generate segmentation, register to template and extract metrics at C2-C3.
#
# Note: All images have .nii extension.
#
# Usage:
#   ./process_data.sh <SUBJECT_ID> <FILEPARAM>
#
# Author: Julien Cohen-Adad

# Uncomment for full verbose
set -v

# Immediately exit if error
set -e

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1
FILEPARAM=$2


# FUNCTIONS
# ==============================================================================

# Check if manual label already exists. If it does, copy it locally. If it does
# not, perform labeling.
label_if_does_not_exist(){
  local file="$1"
  local file_seg="$2"
  # Update global variable with segmentation file name
  FILELABEL="${file}_labels"
  if [ -e "${PATH_SEGMANUAL}/${file}_labels-manual.nii" ]; then
    echo "Found manual label: ${PATH_SEGMANUAL}/${file}_labels-manual.nii"
    rsync -avzh "${PATH_SEGMANUAL}/${file}_labels-manual.nii" ${FILELABEL}.nii
  else
    # Generate labeled segmentation
    sct_label_vertebrae -i ${file}.nii -s ${file_seg}.nii -c t1 -qc ${PATH_QC} -qc-subject ${SUBJECT}
    # Create labels in the cord at C2 and C3 mid-vertebral levels
    sct_label_utils -i ${file_seg}_labeled.nii -vert-body 2,3 -o ${FILELABEL}.nii
  fi
}

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  if [ -e "${PATH_SEGMANUAL}/${FILESEG}-manual.nii" ]; then
    echo "Found manual segmentation: ${PATH_SEGMANUAL}/${FILESEG}-manual.nii"
    rsync -avzh "${PATH_SEGMANUAL}/${FILESEG}-manual.nii" ${FILESEG}.nii
    sct_qc -i ${file}.nii -s ${FILESEG}.nii -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}


# SCRIPT STARTS HERE
# ==============================================================================
source $FILEPARAM
# Go to results folder, where most of the outputs will be located
cd $PATH_RESULTS
# Copy source images
mkdir -p data
cd data
cp -r $PATH_DATA/$SUBJECT .
# Go to data folder
cd $SUBJECT/anat/
# Setup file names
file_t1w=${SUBJECT}_echo-MEAN_T1w
file_r1=${SUBJECT}_RFSC_R1
file_r2s=${SUBJECT}_RFSC_R2s_OLS
file_pd=${SUBJECT}_RFSC_PD
file_mt=${SUBJECT}_RFSC_MT
# Average all echoes of the T1w images
sct_image -i ${SUBJECT}_echo-?_T1w.nii -concat t -o ${SUBJECT}_echo-ALL_T1w.nii
sct_maths -i ${SUBJECT}_echo-ALL_T1w.nii -mean t -o $file_t1w.nii
# Copy header from correct header (because q/sform are different)
sct_image -i $file_r1.nii -copy-header $file_t1w.nii
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1w "t1"
file_seg=$FILESEG
# Create labels in the cord at C2 and C3 mid-vertebral levels (only if it does not exist)
label_if_does_not_exist $file_t1w $file_seg
file_label=$FILELABEL
# Register to template
# Note: for such a small rostro-caudal distance, we can use -ref subject
sct_register_to_template -i $file_t1w.nii -s $file_seg.nii -l $file_label.nii -c t1 -ref subject -param step=1,type=seg,algo=centermassrot:step=2,type=im,algo=syn,iter=5,slicewise=1,metric=CC,smooth=0 -qc $PATH_QC
# Warp template
sct_warp_template -d $file_t1w.nii -w warp_template2anat.nii.gz -qc $PATH_QC
# Check registration across metrics
sct_qc -i $file_r2s.nii -s $file_seg.nii -p sct_propseg -qc $PATH_QC
sct_qc -i $file_pd.nii -s $file_seg.nii -p sct_propseg -qc $PATH_QC
sct_qc -i $file_mt.nii -s $file_seg.nii -p sct_propseg -qc $PATH_QC
# Compute average CSA between C2 and C3 levels (append across subjects)
sct_process_segmentation -i $file_seg.nii -vert 2:3 -o $PATH_RESULTS/CSA.csv -append 1 -qc $PATH_QC
# Compute average MPM metrics in the spinal cord white matter between C2 and C3 levels (append across subjects)
sct_extract_metric -i $file_r1.nii -vert 2:3 -l 51 -o $PATH_RESULTS/R1.csv -append 1
sct_extract_metric -i $file_r2s.nii -vert 2:3 -l 51 -o $PATH_RESULTS/R2s.csv -append 1
sct_extract_metric -i $file_pd.nii -vert 2:3 -l 51 -o $PATH_RESULTS/PD.csv -append 1
sct_extract_metric -i $file_mt.nii -vert 2:3 -l 51 -o $PATH_RESULTS/MT.csv -append 1
