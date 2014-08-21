# brain-behavior-change-processing

Processing &amp; analysis scripts for the Brain Behavior Change Program (BBCP)


## Directory Structure

### Study directories
    bbcp - Studies - StudyName - Designs: design files for task fMRI
                               - Docs:
                               - Figures: 
                               - GroupResults: group-wise statistics
                               - Manuscripts: 
                               - Scripts: study-specific scripts 
                               - Subjects: subject data (see below)
                               - Templates: image templates, priors, labels, etc

### Subject data directories
    Subjects - SubjectID - AcquisitionID - Images: MR data (see below)
                                         - Info: demographic info, non image-specific behavior info

### Image data directories
    Images - SequenceName - Behavior:
                          - Dicoms: zipped tar file of original dicom images
                          - NIFTIs: reconstructed image data (minimally processed)
                          - QA: quality assurance info
                          - Results: processed image data
  

