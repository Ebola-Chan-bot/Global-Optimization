function V = Version(AlwaysCheck)
arguments
	AlwaysCheck=false;
end
persistent pVersion
if isempty(pVersion)||AlwaysCheck
	V='3.3.1';
	if~isempty(metafunction('TextAnalytics.CheckUpdateFromGitHub'))
		TextAnalytics.CheckUpdateFromGitHub('https://github.com/Ebola-Chan-bot/Global-Optimization/releases','埃博拉酱的全局优化工具箱',['v',V]);
	end
	pVersion.Me=matlab.mpm.Version(V);
	pVersion.MATLAB='R2025a';
	pVersion.Dependencies=array2table(["MATLAB"	"20.2.4"	"https://github.com/Ebola-Chan-bot/MATLAB-Extension/releases"],VariableNames=["Namespace","Version","URL"]);
	pVersion.Dependencies.Version=matlab.mpm.Version(pVersion.Dependencies.Version);
	for D=1:height(pVersion.Dependencies)
		Namespace=pVersion.Dependencies.Namespace(D);
		MpmVersion=Namespace+".Version";
		EarliestVersion=pVersion.Dependencies.Version(D);
		URL=pVersion.Dependencies.URL(D);
		if isempty(metafunction(MpmVersion))
			warning('GlobalOptimization:Exception:Lack_dependence','GlobalOptimization:Exception:Lack_dependence：<a href="%s">%s v%s</a>',URL,Namespace,EarliestVersion);
		else
			MpmVersion=feval(MpmVersion).Me;
			for F=["Major","Minor","Patch"]
				if EarliestVersion.(F)<MpmVersion.(F)
					break;
				elseif EarliestVersion.(F)>MpmVersion.(F)
					warning('GlobalOptimization:Exception:Dependence_version_too_low','GlobalOptimization:Exception:Dependence_version_too_low：<a href="%s">%s v%s</a>',URL,Namespace,EarliestVersion);
					break;
				end
			end
		end
	end
end
V=pVersion;