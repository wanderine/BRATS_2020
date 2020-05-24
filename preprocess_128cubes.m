close all
clear all
clc

addpath('/home/andek67/Research_projects/nifti_matlab')

BRATSDatapath = ['/flush2/common/BRATS_2020/MICCAI_BraTS2020_TrainingData/'];
segmentationDatapath = ['/flush2/common/BRATS_2020_FSL_segmentations/'];
augmentedDatapath = ['/flush2/common/BRATS_2020_preprocessed_128cubes/'];

numberOfTrainingSubjects = 369;

MRfilenames = dir([BRATSDatapath]);
MRfilenames = MRfilenames(3:end);

nii = load_nii([BRATSDatapath '/BraTS20_Training_001/BraTS20_Training_001_t1.nii']);
volume = double(nii.img);
[sy sx sz scA] = size(volume);

scB = 6; % Number of FAST segmentation channels (GM, WM, CSF, TMR1, TMR2, TMR3)

[xi, yi, zi] = meshgrid(-(sx-1)/2:(sx-1)/2,-(sy-1)/2:(sy-1)/2, -(sz-1)/2:(sz-1)/2);

for subject = 1:numberOfTrainingSubjects
    
    subject
    
    for augmentation = 1:10
        
        x_rotation = 15 * randn;
        y_rotation = 15 * randn;
        z_rotation = 15 * randn;
        
        
        R_x = [1                        0                           0;
            0                        cos(x_rotation*pi/180)      -sin(x_rotation*pi/180);
            0                        sin(x_rotation*pi/180)      cos(x_rotation*pi/180)];
        
        R_y = [cos(y_rotation*pi/180)   0                           sin(y_rotation*pi/180);
            0                        1                           0;
            -sin(y_rotation*pi/180)  0                           cos(y_rotation*pi/180)];
        
        R_z = [cos(z_rotation*pi/180)   -sin(z_rotation*pi/180)     0;
            sin(z_rotation*pi/180)   cos(z_rotation*pi/180)      0;
            0                        0                           1];
        
        % Shrink volumes to fit in 128 cube volumes
        Scaling = [1.4 0  0;
                   0  1.4 0;
                   0  0  1.4];
        
        Rotation_matrix = R_x * R_y * R_z * Scaling;
        Rotation_matrix = Rotation_matrix(:);
        
        rx_r = zeros(sy,sx,sz);
        ry_r = zeros(sy,sx,sz);
        rz_r = zeros(sy,sx,sz);
        
        rx_r(:) = [xi(:) yi(:) zi(:)]*Rotation_matrix(1:3);
        ry_r(:) = [xi(:) yi(:) zi(:)]*Rotation_matrix(4:6);
        rz_r(:) = [xi(:) yi(:) zi(:)]*Rotation_matrix(7:9);
        
        %----
        
        if subject < 10
            niiT1 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_00' num2str(subject) '_t1.nii' ]);
            niiT1ce = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_00' num2str(subject) '_t1ce.nii' ]);
            niiT2 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_00' num2str(subject) '_t2.nii' ]);
            niiFLAIR = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_00' num2str(subject) '_flair.nii' ]);
        elseif subject < 100
            niiT1 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_0' num2str(subject) '_t1.nii' ]);
            niiT1ce = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_0' num2str(subject) '_t1ce.nii' ]);
            niiT2 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_0' num2str(subject) '_t2.nii' ]);
            niiFLAIR = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_0' num2str(subject) '_flair.nii' ]);
        else
            niiT1 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_' num2str(subject) '_t1.nii' ]);
            niiT1ce = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_' num2str(subject) '_t1ce.nii' ]);
            niiT2 = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_' num2str(subject) '_t2.nii' ]);
            niiFLAIR = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_' num2str(subject) '_flair.nii' ]);
        end
        
        volumes = zeros(sy,sx,sz,4);
        volumes(:,:,:,1) = double(niiT1.img);
        volumes(:,:,:,2) = double(niiT1ce.img);
        volumes(:,:,:,3) = double(niiT2.img);
        volumes(:,:,:,4) = double(niiFLAIR.img);
        
        newVolumes = zeros(size(volumes));
        
        for c = 1:4
            % Add augmentation
            newVolume = interp3(xi,yi,zi,volumes(:,:,:,c),rx_r,ry_r,rz_r,'cubic');
            % Remove 'not are numbers' from interpolation
            newVolume(isnan(newVolume)) = 0;
            newVolumes(:,:,:,c) = newVolume;
        end
        
        % Crop to 128 cubes
        temp = zeros(128,128,128,4);
        temp = newVolumes(57:end-56,57:end-56,15:end-13,:);
        
        newFile.hdr = nii.hdr;
        newFile.hdr.dime.datatype = 16;
        newFile.hdr.dime.bitpix = 16;
        newFile.hdr.dime.dim = [4 128 128 128 4 1 1 1];
        newFile.img = single(temp);
     
        save_nii(newFile,[augmentedDatapath '/trainA/' MRfilenames(subject).name '_MRI_augmented_' num2str(augmentation) '.nii.gz']);
        
        %--------------------
        % Now do the labels
        %--------------------
        
        if subject < 10
            niiTumorLabels = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_00' num2str(subject) '_seg.nii' ]);
            niiFASTLabels= load_nii([segmentationDatapath '/BraTS20_Training_00' num2str(subject) '_seg.nii.gz' ]);
        elseif subject < 100
            niiTumorLabels = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_0' num2str(subject) '_seg.nii' ]);
            niiFASTLabels= load_nii([segmentationDatapath '/BraTS20_Training_0' num2str(subject) '_seg.nii.gz' ]);
        else
            niiTumorLabels = load_nii([BRATSDatapath MRfilenames(subject).name '/BraTS20_Training_' num2str(subject) '_seg.nii' ]);
            niiFASTLabels= load_nii([segmentationDatapath '/BraTS20_Training_' num2str(subject) '_seg.nii.gz' ]);
        end
        
        temp1 = double(niiFASTLabels.img);
        temp2 = double(niiTumorLabels.img);
        
        volumes = zeros(sy,sx,sz);
        % Set GM WM CSF
        volumes(temp1 == 1) = 100;
        volumes(temp1 == 2) = 200;
        volumes(temp1 == 3) = 300;
        % Now set tumour labels, 
        % will remove parts of GM WM CSF previously set
        volumes(temp2 == 1) = 400;
        volumes(temp2 == 2) = 500;
        volumes(temp2 == 4) = 600;
        
        % Add augmentation using nearest interpolation to keep integers
        newVolume = interp3(xi,yi,zi,volumes,rx_r,ry_r,rz_r,'nearest');
        % Remove 'not are numbers' from interpolation
        newVolume(isnan(newVolume)) = 0;
        
        % Crop to 128 cubes
        temp = zeros(128,128,128);
        temp = newVolume(57:end-56,57:end-56,15:end-13);
        
        newFile.hdr = nii.hdr;
        newFile.hdr.dime.datatype = 16;
        newFile.hdr.dime.bitpix = 16;
        newFile.hdr.dime.dim = [3 128 128 128 1 1 1 1];
        newFile.img = single(temp);
        
        save_nii(newFile,[augmentedDatapath '/trainB/' MRfilenames(subject).name '_labels_augmented_' num2str(augmentation) '.nii.gz']);
        
        
    end
end


