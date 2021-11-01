function MD = MinDistanceOF(PointMatrix,FixedPoints)
persistent ColorWeights
if isempty(ColorWeights)
	ColorWeights=reshape([0.2989 0.5870 0.1140],1,1,1,3);
end
NoTrials=height(PointMatrix);
PointMatrix=reshape([reshape(PointMatrix,NoTrials,[],3) repmat(FixedPoints,NoTrials,1)],NoTrials,[],1,3);
MD=sum(((PointMatrix-permute(PointMatrix,[1 3 2 4])).*ColorWeights).^2,4);
MD(repmat(shiftdim(logical(eye(size(MD,2))),-1),NoTrials,1,1))=NaN;
MD=-min(MD,[],[2 3]);