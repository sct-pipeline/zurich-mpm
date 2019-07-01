# zurich-mpm
Processing pipeline for test-retest MPM data

### Organization of data

Data are organized according to the [BIDS](https://bids.neuroimaging.io/) convention for multiple sessions:
~~~
mpm_data
  ├── dataset_description.json
  ├── participants.json
  ├── participants.tsv
  ├── sub-01
  ├── sub-02
  └── sub-03
      ├── ses-01
      └── ses-02
          └── anat
              ├── sub-03_ses-02_RFSC_MT.nii.gz
              ├── sub-03_ses-02_RFSC_MT.json
              ├── sub-03_ses-02_RFSC_PD.nii.gz
              ├── sub-03_ses-02_RFSC_PD.json
              ├── sub-03_ses-02_RFSC_R1.nii.gz
              ├── sub-03_ses-02_RFSC_R1.json
              ├── sub-03_ses-02_RFSC_R2s_OLS.nii.gz
              └── sub-03_ses-02_RFSC_R2s_OLS.json
~~~
