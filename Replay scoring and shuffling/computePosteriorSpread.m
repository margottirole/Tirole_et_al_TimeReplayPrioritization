function [postSpread,mSquared,COM]= computePosteriorSpread(posterior)
parameters= list_of_parameters;

x_pos= 0:parameters.x_bins_width_bayesian:size(posterior,1)*parameters.x_bins_width_bayesian;
x_bin_ctrs= x_pos(1:end-1)+parameters.x_bins_width_bayesian/2;

COM= NaN(1,size(posterior,2));
mSquared= NaN(1,size(posterior,2));
for ii=1:size(posterior,2)
    % get COM
    COM_tmp= [];
    for jj=1:size(posterior,1)
        COM_tmp(jj)= posterior(jj,ii).*x_bin_ctrs(jj);
    end
    COM(ii)= sum(COM_tmp)./sum(posterior(:,ii));
    % get second moment of posterior
    mSquared_tmp= [];
    for jj=1:size(posterior,1)
        mSquared_tmp(jj)= posterior(jj,ii)*(x_bin_ctrs(jj) - COM(ii)).^2;
    end
    mSquared(ii)= sum(mSquared_tmp);
    postSpread= median(sqrt(mSquared));

end

% figure(); 
% imagesc(1:size(posterior,2),x_bin_ctrs,posterior);
% set(gca,'YDir','normal')
% hold on; plot(COM,'r+')
% title(['posterior spread= ' num2str(postSpread) ' (cm)'])

end
