% Page formatting
\LoadClass[11pt]{article}
\usepackage[letterpaper, margin=1in, includefoot]{geometry}
\linespread{2}
\addtolength{\footnotesep}{\baselineskip}

% Packages
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{color}
\usepackage{csvsimple}
\usepackage[bottom]{footmisc}               % Footnote at page bottom
\usepackage{graphicx}                       % Graphics support
\usepackage{hyperref}                       % URL support


% Floats
\usepackage{caption}
\usepackage{float}
\usepackage[section]{placeins}
\usepackage{subcaption}
\renewcommand\theContinuedFloat{(\alph{ContinuedFloat})}
\makeatletter
\AtBeginDocument{%
  \expandafter\renewcommand\expandafter\subsection\expandafter{%
    \expandafter\@fb@secFB\subsection
  }%
}
\makeatother

% Citations
\usepackage{bibentry}
\usepackage{natbib}

% Switch \epsilon and \varepsilon
\let\oldepsilon\epsilon
\let\oldvarepsilon\varepsilon
\renewcommand{\epsilon}{\oldvarepsilon}
\renewcommand{\varepsilon}{\oldepsilon}

% Single-space matrices
\renewcommand*{\arraystretch}{0.625}

% Left and right brackets
\newcommand{\paren}[1]{\left( #1 \right)}
\newcommand{\bracket}[1]{\left[ #1 \right]}
\newcommand{\curly}[1]{\left\{ #1 \right\}}
\newcommand{\inner}[1]{\left\langle #1 \right\rangle}
\newcommand{\floor}[1]{\left\lfloor #1 \right\rfloor}
\newcommand{\ceil}[1]{\left\lceil #1 \right\rceil}
\newcommand{\abs}[1]{\left| #1 \right|}     % Absolute value
\newcommand{\norm}[1]{\lVert #1 \rVert}     % Norm
\newcommand{\eval}[1]{\left. #1 \right|}    % Evaluated at

% General math commands
\def\d{\partial}
\def\E{\mathbb{E}}
\def\Var{\mathrm{Var}}
\def\Cov{\mathrm{Cov}}