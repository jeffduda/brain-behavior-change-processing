% test the MPRAGE Qa script results

%cd /import/monstrum/Users/melliot/programs/scripts

v0 = load_untouch_nii('MPRAGE_TI1100_ipat2.nii');
m1 = load_untouch_nii('mask1.nii');
m2 = load_untouch_nii('mask2.nii');
m3 = load_untouch_nii('mask3.nii');

p1 = find(m1.img(:) == 1);
p3 = find(m3.img(:) == 1);

im0      = double(v0.img);
sigmean  = mean(im0(p1))
sigstdev =  std(im0(p3))

smax    = max(im0(p1));
bins    = 0:10:smax;
[h1,x1] = hist(im0(p1),bins);

smax    = max(im0(p3));
bins    = 0:1:smax;
[h2,x2] = hist(im0(p3),bins);

bar(x1,h1/max(h1(:)),'b')
hold on
bar(x2,h2/max(h2(:)),'r')
hold off