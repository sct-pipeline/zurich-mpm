# zurich-mpm
Processing pipeline for test-retest MPM data

## Getting started

- Optional: install GNU parallel (to distribute processing across CPU cores)
- Copy `parameters_template.sh` to `parameters.sh` and update fields with your local config (notably variable PATH_PARENT)
- Update permission:
  ~~~
  chmod 775 process_data.sh
  ~~~
- Run:
  ~~~
  sct_run_batch parameters.sh process_data.sh
  ~~~
- Check QC report (under results/qc/index.html) and results/

## Data

Data are organized according to the [BIDS](https://bids.neuroimaging.io/) convention for multiple sessions:
~~~
mpm_data
  ├── sub-01_ses-01
  ├── sub-01_ses-02
  ├── sub-02_ses-01
  └── sub-02_ses-02
      └── anat
          ├── sub-02_ses-02_RFSC_MT.nii
          ├── sub-02_ses-02_RFSC_PD.nii
          ├── sub-02_ses-02_RFSC_R1.nii
          ├── sub-02_ses-02_RFSC_R2s_OLS.nii
~~~

## SCT version

This pipeline has been tested on 4.0.1, which can be downloaded here:
https://github.com/neuropoly/spinalcordtoolbox/releases
