function [dir1, dir2] = extract_tracking_direction(smoothpos,thresh)

smoothdir = diff(smoothpos);
dir1idx = smoothdir > thresh.min_dir_size;
dir2idx = smoothdir < -thresh.min_dir_size;

% remove direction trajectories shorter than minimum
indxs.dir1 = position_and_length_of_true_indices(dir1idx);
indxs.dir1(indxs.dir1(:,3)< thresh.min_trajectory_length,:) = [];
indxs.dir2 = position_and_length_of_true_indices(dir2idx);
indxs.dir2(indxs.dir2(:,3)< thresh.min_trajectory_length,:) = [];

dir1cleanIdx = make_logical_index_from_indices(indxs.dir1,length(dir1idx));
dir2cleanIdx = make_logical_index_from_indices(indxs.dir2,length(dir2idx));

dir1 = position_and_length_of_true_indices(dir1cleanIdx);
dir2 = position_and_length_of_true_indices(dir2cleanIdx);

dir1 = dir1(:,1:2);
dir2 = dir2(:,1:2);

end