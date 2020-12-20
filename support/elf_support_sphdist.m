function d = elf_support_sphdist(azi1, ele1, azi2, ele2)
% ELF_SUPPORT_CIRCLE calculates the great-circle distance between two points using the
% haversine formula (more complicated but better-conditioned for small angles)

da = azi2 - azi1;
de = ele2 - ele1;

d = 2 * asind(sqrt(sind(de/2).^2 + cosd(ele1) .* cosd(ele2) .* sind(da/2).^2));