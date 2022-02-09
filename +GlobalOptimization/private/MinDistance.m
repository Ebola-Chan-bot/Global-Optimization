function MD = MinDistance(Points,ColorsToAvoid)
persistent ColorWeights
if isempty(ColorWeights)
	ColorWeights=reshape([0.2989 0.5870 0.1140],1,1,3);
end
Points=[reshape(Points,[],1,3);ColorsToAvoid];
MD=(Points-permute(Points,[2 1 3])).*ColorWeights;
MD=sum(MD.*MD,3);
MD(1:height(MD)+1:end)=NaN;
MD=-min(MD(:));