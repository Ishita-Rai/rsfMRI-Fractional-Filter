%% ********************* Evaluation measures *********************************************
% this code can be used to find the evaluation metrics of pre and post
% filtered data. From the main dataset get original dataset as rfMRI_ip  
% and ARFIMA filtered ouput as fmri_Op. For performing eigenmode analysis, 
% first run the code with rfMRI_ip, save variables whatever required and
% then run that part for the output system (replace rfMRI_ip with fmri_Op)
% After this, use brain overlay code for plotting the data on brain
% overlays. Also, the mapping between cluster formed from input and output 
% data may not be one to one so, visual comparison need to be done to align
% the input and output clusters.
%% define constants
n = 100; % number of brain regions
m = 98*4; % number of datasets, 15 is the subject number and 4 the 4 different resting states
t = 1200; % number of data point in each time series
fs = 1000/720; % sampling frequency = 1/TR where TR is the repetition time
%% ********************* Normalised Power Spectrum *********************************************
figure();
plot_power_spec(rfMRI_ip(1,(1200*11-(1200-1):1200*11)),fs,'norm');
hold on;
plot_power_spec(fmri_Op(1,(1200*11-(1200-1):1200*11)),fs,'norm');
xlabel('Frequency (Hz)');
ylabel('\Delta |P(f)|');
%% ********************* Functional Connectivity (input) *********************************************
% Pearson Correlation and Coherence
for j = 1:m
    R(:,((n*j-(n-1)):n*j)) = corrcoef(rfMRI_ip(:,(t*j-(t-1)):t*j)');
    Cxy(:,((n*j-(n-1)):n*j)) = mscohere_matrix(rfMRI_ip(:,(t*j-(t-1)):t*j)',fs);
end
% Mean FC matrix (averaged over all subjects)
mean_correlation = R(:,((n-(n-1)):n))+ R(:,((n*2-(n-1)):n*2));
for j = 3:m
    mean_correlation = mean_correlation+ R(:,((n*j-(n-1)):n*j));
end
mean_correlation = mean_correlation./m;
mean_coherence = Cxy(:,((n-(n-1)):n))+ Cxy(:,((n*2-(n-1)):n*2));
for j = 3:m
    mean_coherence = mean_coherence+ Cxy(:,((n*j-(n-1)):n*j));
end
mean_coherence = mean_coherence./m;
% Standard Deviation FC 
for i = 1:n
    for k = 1:n
        for j = 1:m
            sd_correlation(k,j) = R(k,((100*j)-(100-1)+i-1));
            sd_coherence(k,j) = Cxy(k,((100*j)-(100-1)+i-1));
        end
    end
Scorrelation(:,i) = std(sd_correlation,0,2);
Scoherence(:,i) = std(sd_coherence,0,2);
end
%% ********************* Functional Connectivity (output) *********************************************
% Pearson Correlation and Coherence
for j = 1:m
    Rop(:,((n*j-(n-1)):n*j)) = corrcoef(fmri_Op(:,(t*j-(t-1)):t*j)');
    Cxyop(:,((n*j-(n-1)):n*j)) = mscohere_matrix(fmri_Op(:,(t*j-(t-1)):t*j)',fs);
end
% Mean FC matrix (averaged over all subjects)
mean_correlationop = Rop(:,((n-(n-1)):n))+ Rop(:,((n*2-(n-1)):n*2));
for j = 3:m
    mean_correlationop = mean_correlationop+ Rop(:,((n*j-(n-1)):n*j));
end
mean_correlationop = mean_correlationop./m;
mean_coherenceop = Cxyop(:,((n-(n-1)):n))+ Cxyop(:,((n*2-(n-1)):n*2));
for j = 3:m
    mean_coherenceop = mean_coherenceop+ Cxyop(:,((n*j-(n-1)):n*j));
end
mean_coherenceop = mean_coherenceop./m;
% Standard Deviation FC 
for i = 1:n
    for k = 1:n
        for j = 1:m
            sd_correlationop(k,j) = Rop(k,((100*j)-(100-1)+i-1));
            sd_coherenceop(k,j) = Cxyop(k,((100*j)-(100-1)+i-1));
        end
    end
Scorrelationop(:,i) = std(sd_correlationop,0,2);
Scoherenceop(:,i) = std(sd_coherenceop,0,2);
end
%% ********************* Eigen Brain Analysis *********************************************
% find eigen modes of original rs-fMRI signal using arfit
for j = 1:m
   [~,A]=arfit(rfMRI_ip(:,(t*j-(t-1)):t*j)',1,1);
   [V(:,(n*j-(n-1)):n*j),D(:,(n*j-(n-1)):n*j)] = eig(A); % Eigen vector and eigen value
end
% Normalise eigen vectors
for i = 1:n*m 
    Vs_norm(:,i) = abs(V(:,i))./max(abs(V(:,i)));
end
%% cluster eigen-vectors using k-means clustering
k = 5; % number of clusters 
[idx2,center2,~,Distance] = kmeans(abs(Vs_norm.'),k); % clustering eigenvectors
% Normalise centroid eigen vector after kmeans clustering
for i = 1:5
    centermin = center2(i,:)- min(center2(i,:));
    norm_center2(i,:) = centermin./max(abs(centermin)); % Cluster centroid to plot on brain overlay
end
clear i
%% divide eigen values based on clustering performed on eigen vectors
idx22 = zeros(n,m);
for i = 1:m
idx22(:,i) = idx2((n*i-(n-1)):n*i,1);
end
l_d_cluster = D; % D is the matrix of eigen values
l_d_cluster3 = zeros(n,m);
for i = 1:n
    l_d_cluster2 = l_d_cluster(i,:);
    l_d_cluster2(find(l_d_cluster2==0))=[];
    l_d_cluster3(i,:) = l_d_cluster2;
end
l_d_cluster4 = zeros(n,k);
l_d_cluster5 = zeros(n,k);
l_d_cluster6 = zeros(k,n*m);
for i = 1:m
    for j = 1:n
        l_d_idx = idx22(j,i);
        l_d_cluster4(j,l_d_idx) = l_d_cluster3(j,i);
        l_d_cluster5 = l_d_cluster4.';
    end
    l_d_cluster6(:,(n*i-(n-1)):n*i) = l_d_cluster5;
end
% plot eigen values
for i = 1:k
    l_d_cluster7 = l_d_cluster6(i,:);
    X=real(l_d_cluster7);
    Y=imag(l_d_cluster7);
    scatter(X,Y,5,'.');
    xlabel('Real Part')
    ylabel('Imaginary Part')
    legend('Cluster1','Cluster2','Cluster3','Cluster4','Cluster5')
    hold on
end
hold off
%% Spatial frequency on the basis of eigen values i.e. f = (theta/2pi)*fs where theta is the angle of complex eigen values
for j = 1:k
    for i = 1:m*n
        % accounting for negative theta
        theta(j,i) = angle(l_d_cluster6(j,i));
        f(j,i) = abs((theta(j,i)*fs)/(2*pi));
    end
end
%% Stability
for i = 1:k
    stability(i,:) = abs(l_d_cluster6(i,:));
end
for i = 1:k
    scatter(abs(f(i,:)),stability(i,:),5,'.');
    legend('Cluster1','Cluster2','Cluster3','Cluster4','Cluster5')
    hold on;
end
hold off;

%% plot mean and standard deviation of spatial frequency vs stability  in each cluster
for i = 1:5
    mean_eig = mean(f(i,:));
    std_frequency = std(f(i,:));
    mean_St= mean(stability(i,:));
    std_stability = std(stability(i,:));
    scatter(abs(mean_eig),mean_St,100,'filled','o');
    errorbar(abs(mean_eig),mean_St,std_frequency,'horizontal');
    errorbar(abs(mean_eig),mean_St,std_stability);
end

