## NI-KOP
### Domáca úloha č. 5

##### Návod na spustenie
Stiahnite si repozitár z https://gitlab.fit.cvut.cz/sutymate/ni-kop.
Algoritmus na riešenie SAT sa nachádza v HW/5.
Spustite ho v príkazovom riadku v prostredí Julia.
> julia runCL.jl -v -g <instance_path>

Výstup programu bez argumentov je v tvare:
> instance_name

> price iterations

> instance_name

> price iterations
...

Kde _price_ je suma váh splnených premenných a _iterations_ je počet navštívených stavov.

Argumenty:
> -v    : not default, verbose, prints text output
-g:     not default, shows graph of iteration

Spúšťací skript _runCL.jl_ môžete upraviť, napríklad manuálne nastaviť hodnoty počiatočnej teploty, faktoru ochladzovania, reštarty atd.



