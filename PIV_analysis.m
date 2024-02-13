% Transform velocities to angular velocities

classdef PIV_analysis
    methods
        function [mask, centroid] = clean_mask(obj, binaryImage)
            stats = regionprops(binaryImage, 'Centroid', 'Area', 'PixelList', 'Circularity');
            im_dims = size(binaryImage);
            area = im_dims(1)*im_dims(2)* 0.1; % minimum accepted size is 10% of the image area
            id_mask = 0;
            for k = 1:length(stats)
                if stats(k).Area > area
                    centroid = round(stats(k).Centroid);
                    centroid = [centroid(2) centroid(1)];
                    area = stats(k).Area;
                    id_mask = k;

                end
            end
            if id_mask == 0
                mask = zeros(size(binaryImage)); % if no fitting mask was found return an emtpy mask - the velocities of the frame will be set to zero
                centroid = [0 0];
                return
            end
            mask = zeros(size(binaryImage));
            pixel_list = stats(id_mask).PixelList;
            for k = 1:length(pixel_list)
                mask(pixel_list(k,2), pixel_list(k,1)) = 1;
            end
            mask2 = imfill(mask);
            seD = strel('diamond', 3);
            mask3 = imerode(mask2,seD);
            binaryImage = mask3 == 1;
            stats = regionprops(binaryImage, 'Centroid', 'Area', 'PixelList');
            % iterate over the mask again to make sure we dont have
            % multiple areas after the errosion
            area = 0;
            id_mask = 0;
            for k = 1:length(stats)
                if stats(k).Area > area
                    centroid = round(stats(k).Centroid);
                    centroid = [centroid(2) centroid(1)];
                    area = stats(k).Area;
                    id_mask = k;

                end
            end
            mask = zeros(size(binaryImage));
            pixel_list = stats(id_mask).PixelList;
            for k = 1:length(pixel_list)
                mask(pixel_list(k,2), pixel_list(k,1)) = 1;
            end

            %figure
            %imagesc(mask)
        end
        function [u_list, v_list, uv_list] = load_pivs(obj, path, stacks)


                u_list = {};
                v_list = {};
                uv_list = {};
                load(path);
                emptyCellIndices = cellfun('isempty', u_filtered);

                % Remove empty cells using logical indexing
                dims = size(u_filtered{1});
                avgs = zeros(dims);
                avgs_shift = avgs;
                center = round(dims/2);
                %center = [center(2) center(1)]; %% validate sometime

                u_filtered = u_filtered(~emptyCellIndices);
                v_filtered = v_filtered(~emptyCellIndices);

                %% center the velocity vectors
                for j = 1:length(v_filtered)

                    shifted_u = zeros(dims);
                    shifted_v = zeros(dims);
                    binaryImage = typevector_filtered{j} == 1;

                    [mask, centroid] = obj.clean_mask(binaryImage);
                    if sum(sum(mask)) == 0 % the clean_mask function returns an empty mask if no fitting mask was found
                        continue
                    end
                    shift = center - centroid; % [3,3] - [2,2] = 1,1 --> shift to right, down


                    %typ_temp = zeros(size(v_filtered{j}));
                    %typ_temp(typevector_filtered{j} == 1) = 1;

                    u = u_filtered{j} .* mask;
                    v = v_filtered{j} .* mask;

                    if shift(1) >= 0
                        if shift(2) >= 0
                            %shift down right
                            shifted_v(1+shift(1):end, 1+shift(2):end) = v(1:dims(1)-shift(1), 1:dims(2)-shift(2));
                            shifted_u(1+shift(1):end, 1+shift(2):end) = u(1:dims(1)-shift(1), 1:dims(2)-shift(2));

                        else
                            %shift down left
                            shifted_v(1+shift(1):end, 1:abs(dims(2)+shift(2))) = v(1:dims(1)-shift(1), 1-shift(2):end);
                            shifted_u(1+shift(1):end, 1:abs(dims(2)+shift(2))) = u(1:dims(1)-shift(1), 1-shift(2):end);

                        end
                    else
                        if shift(2) > 0
                            %shift up right
                            shifted_v(1:dims(1)+shift(1), 1+shift(2):end) = v(1-shift(1):end, 1:dims(2)-shift(2));
                            shifted_u(1:dims(1)+shift(1), 1+shift(2):end) = u(1-shift(1):end, 1:dims(2)-shift(2));

                        else
                            %shift down left
                            shifted_v(1:dims(1)+shift(1), 1:abs(dims(2)+shift(2))) = v(1-shift(1):end, 1-shift(2):end);
                            shifted_u(1:dims(1)+shift(1), 1:abs(dims(2)+shift(2))) = u(1-shift(1):end, 1-shift(2):end);

                        end
                    end
                    %shifted_u = (shifted_u- mean(mean(shifted_u))).* mask;
                    %shifted_v = (shifted_v- mean(mean(shifted_v))).* mask;

                    uv = (shifted_v.^2 + shifted_u.^2).^0.5;

                    
                u_list{end+1} = shifted_u;
                v_list{end+1} = shifted_v;
                uv_list{end+1} = uv;


                end
            
        end
        
        function [shear_x, shear_y, shear_abs] = get_shear_rates(obj,u,v)
            shear_x = {};
            shear_y = {};
            shear_abs = {};
            for i=1:length(u)
                shear_x{i}  = diff(u{i},1,1);
                shear_y{i}  = diff(v{i},1,2);
                shear_abs{i} = abs(shear_y{i}(1:end-1, :)) + abs(shear_x{i}(:,1:end-1));
            end

        end
        function [avgs_speed] = get_heatmap(obj, uv, fig_title, limits, path, save_figs)
            avgs_speed = zeros(size(uv{1}));

            for i = 1:length(uv)


                avgs_speed = avgs_speed + uv{i};
            end
            avgs_speed = avgs_speed / length(uv);

            if save_figs == 1
                if exist(path, 'dir') == 0
                    mkdir(path);
                end
                temp_fig = figure('Visible', 'off');
                
                if isempty(limits)
                    heatmap(avgs_speed);
                else
                    heatmap(avgs_speed, 'ColorLimits', limits);
                end

                % Turn off x-axis ticks
                %h.XDisplayLabels = {};

                title(fig_title);
                grid off;
                saveas(temp_fig, [path, fig_title], 'bmp');
            end
        end



        function [velocity_profile] = get_velocity_curve(obj,avgs_avg )

            shape = size(avgs_avg);
            center_dist = round(size(avgs_avg)/2);

            velocity_profile = zeros(max(size(avgs_avg)),2);
            for i = 1:shape(1)
                for j = 1:shape(2)
                    distance = sqrt((i-center_dist(1))^2 + (j-center_dist(2))^2)+0.5;
                    velocity_profile(round(distance),1) = velocity_profile(round(distance),1) + avgs_avg(i,j);
                    velocity_profile(round(distance),2) = velocity_profile(round(distance),2) +1;
                end
            end
            velocity_profile = velocity_profile(:,1) ./ velocity_profile(:,2);

        end




    end
end

