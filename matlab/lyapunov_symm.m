function [x,u]=lyapunov_symm(a,b,qz_criterium)
% Solves the Lyapunov equation x-a*x*a' = b, for b (and then x) symmetrical
% if a has some unit roots, the function computes only the solution of the stable subsystem
%  
% INPUTS:
%   a:      coefficient matrix (n x n)  
%   b:      coefficient square matrix (n x n)
%
% OUTPUTS
%   x:      solution matrix (m x m)
%   ns_var: vector of indices of non-stationary variables (p x 1)
%           (m + p = n)
%   u:      Schur vectors associated with unit roots  
%
% ALGORITHM
%   uses reordered Schur decomposition
%
% SPECIAL REQUIREMENTS
%   needs Matlab version with ordeig function
%
% part of DYNARE, copyright Dynare Team (2006-2008)
% Gnu Public License   

  ns_var = [];
  u = [];
  
  info = 0;
  if size(a,1) == 1
    x=b/(1-a*a);
    return
  end
  [u,t] = schur(a);
  if exist('ordeig','builtin')
    e1 = abs(ordeig(t)) > 2-qz_criterium;
  else
    e1 = abs(my_ordeig(t)) > 2-qz_criterium;
  end
  k = sum(e1);
  if exist('ordschur','builtin')
    % selects stable roots
    [u,t] = ordschur(u,t,e1); 
    n = length(e1)-k;
    b=u(:,k+1:end)'*b*u(:,k+1:end);
    t = t(k+1:end,k+1:end);
  elseif k > 0
    % problem for Matlab version that don't have ordschur
    error(['lyapunov_sym: you need a Matlab version > 6.5 to handle models' ...
	   ' with unit roots'])
  else
    % no unit root
    n = length(e1);
    b=u'*b*u;
  end
  x=zeros(n,n);
  for i=n:-1:2
    if t(i,i-1) == 0
      if i == n
	c = zeros(n,1);
      else
	c = t(1:i,:)*(x(:,i+1:end)*t(i,i+1:end)')+...
	    t(i,i)*t(1:i,i+1:end)*x(i+1:end,i);
      end
      q = eye(i)-t(1:i,1:i)*t(i,i);
      x(1:i,i) = q\(b(1:i,i)+c);
      x(i,1:i-1) = x(1:i-1,i)';
    else
      if i == n
	c = zeros(n,1);
	c1 = zeros(n,1);
      else
	c = t(1:i,:)*(x(:,i+1:end)*t(i,i+1:end)')+...
	    t(i,i)*t(1:i,i+1:end)*x(i+1:end,i)+...
	    t(i,i-1)*t(1:i,i+1:end)*x(i+1:end,i-1);
	c1 = t(1:i,:)*(x(:,i+1:end)*t(i-1,i+1:end)')+...
	     t(i-1,i-1)*t(1:i,i+1:end)*x(i+1:end,i-1)+...
	     t(i-1,i)*t(1:i,i+1:end)*x(i+1:end,i);
      end
      q = [eye(i)-t(1:i,1:i)*t(i,i) -t(1:i,1:i)*t(i,i-1);...
	   -t(1:i,1:i)*t(i-1,i) eye(i)-t(1:i,1:i)*t(i-1,i-1)];
      z =  q\[b(1:i,i)+c;b(1:i,i-1)+c1];
      x(1:i,i) = z(1:i);
      x(1:i,i-1) = z(i+1:end);
      x(i,1:i-1)=x(1:i-1,i)';
      x(i-1,1:i-2)=x(1:i-2,i-1)';
      i = i - 1;
    end
  end
  if i == 2
    c = t(1,:)*(x(:,2:end)*t(1,2:end)')+t(1,1)*t(1,2:end)*x(2:end,1);
    x(1,1)=(b(1,1)+c)/(1-t(1,1)*t(1,1));
  end
  x = u(:,k+1:end)*x*u(:,k+1:end)';
  u = u(:,1:k);