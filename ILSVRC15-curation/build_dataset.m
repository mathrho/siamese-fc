% -------------------------------------------------------------------------------------------------------------------
function build_dataset(data_file,v_1,v_end, root_original, root_crops)
    % Extract and save crops from video v_1 (start from 1) to v_end (check num video in imdb)
	% e.g. save_crops(imdb_video, 1, 1000, '/path/to/original/ILSVRC15/', '/path/to/new/curated/ILSVRC15/')
% -------------------------------------------------------------------------------------------------------------------
    rootDataDir_src = [root_original '/Data/VID/train/'];
    rootDataDir_dest = [root_crops];

    vf = fopen(data_file);
    % first col: ids, second col: nframes, third col: folder
    video_info = textscan(vf,'%s %d %d %d', 'Delimiter', ' ');
    fclose(vf);

    video_paths = video_info{1};
    video_ids = video_info{2};
    video_nframes = video_info{3};
    video_classes = video_info{4};

    saved_crops = 0;
    wfp = fopen('warnings.txt', 'w');
    for v=v_1:v_end

        vid_path = video_paths{v};
        vid_nframes = video_nframes(v);

        if ~exist([rootDataDir_dest vid_path], 'dir')
            mkdir([rootDataDir_dest vid_path])
            mkdir([rootDataDir_dest vid_path '/img'])
        end

        im_scs = zeros(1, vid_nframes);
        for ti=0:(vid_nframes-1)
           
            fprintf('%d (%d)/(%d)\n', v, ti+1, vid_nframes);
            try
                im = imread(sprintf('%s/%06d.JPEG', [rootDataDir_src vid_path], ti));
            catch me
                im = imread(sprintf('%s/%06d.jpg', [rootDataDir_src vid_path], ti));
            end

            [im_patch, im_sc] = rzmax_im(im, 480);
            imwrite(im_patch, sprintf('%s/img/%06d.jpg', [rootDataDir_dest vid_path], ti), 'Quality', 90);

            im_scs(1, ti+1) = im_sc;
        end
        sc = unique(im_scs);
        if numel(sc) > 1
            fprintf(wfp, 'Video does not have consistent frames: %s\n', vid_path)
            sc = max(sc);
        end

        gfp = fopen([rootDataDir_src vid_path '.txt'], 'r')
        rfp = fopen([rootDataDir_dest vid_path '/groundtruth_rect_all.txt'], 'w')
        line = fgetl(gfp);
        while ischar(line)
            V = strsplit(line,',');
            track_id = int32(str2double(V{1}));
            obj_class = int32(str2double(V{2}));
            frame_sz = int32([str2double(V{3}) str2double(V{4})]);
            extent = int32([str2double(V{5}) str2double(V{6}) str2double(V{7}) str2double(V{8})]);
            im_path = strsplit(V{9}, '/');
            im_name = strrep(im_path{end}, '.JPEG', '.jpg');

            %xmin, ymins, ws, hs
            gt_box = round(sc * extent);
            im_patch_w = round(sc * frame_sz(1));
            im_patch_h = round(sc * frame_sz(2));
            im_file = sprintf('%s/img/%s', [rootDataDir_dest vid_path], im_name);
            fprintf(rfp, '%d,%d,%d,%d,%d,%d,%d,%d,%s\n', track_id, obj_class, im_patch_w, im_patch_h, gt_box(1), gt_box(2), gt_box(3), gt_box(4), im_file);
            line = fgetl(gfp);
        end
        fclose(rfp);
        fclose(gfp);
    end

    fclose(wfp);
    fprintf('Finished all videos for dataset: %s\n', data_file);

end


% ---------------------------------------------------------------------------------------------------------------
function [im_patch, sc] = rzmax_im(im, max_sz)
% %%%%%%
% ---------------------------------------------------------------------------------------------------------------
    [im_h,im_w,im_c] = size(im);
    sc = max_sz / max(im_h,im_w);

    
    if sc ~= 1
        im_patch = imresize(im, sc);
    else
        im_patch = im;
    end
end

