# Quando está pronto

Código só é dado como pronto, commitado ou enviado para revisão depois de passar por isto. Cada item existe porque já deixamos passar o erro correspondente.

## 1. Rodar, não supor

- `scripts/verificar.sh` passa: build com `-Werror`, testes, exemplos e hlint.
- Nada é descrito como funcionando sem ter sido executado. Vale para o código e para a documentação: versão de compilador, número de testes e saída de programa citados em README, `CLAUDE.md` ou PR são copiados de uma execução real.

## 2. Tentar quebrar

Os testes que passam foram escritos por quem escreveu o código, e erram junto com ele. Antes de dar por pronto, rode o programa à mão com entradas que os testes **não** cobrem:

- Fronteira de token: palavra reservada colada em letra (`segue_`), número colado em letra (`2pac`), operador que é prefixo de outro (`<` e `<=`, `=` e `==`, `-` e `->`).
- Cada palavra obrigatória de uma regra, removida uma de cada vez.
- O mesmo erro no começo, no meio e no fim do arquivo: a linha e a coluna apontam o lugar certo?
- Arquivo do mundo real: fim de linha do Windows (`\r\n`), BOM no começo, acento, arquivo sem quebra de linha no fim.

Entrada que revelou defeito vira teste.

## 3. Conferir a gramática contra o parser

Produção por produção, nos dois sentidos: tudo o que a gramática aceita o parser aceita, e tudo o que o parser aceita está na gramática.

Atenção a parser pronto de biblioteca (`L.float`, `L.charLiteral`, `L.decimal`): ele costuma aceitar mais do que o nome sugere. Teste o que ele aceita e escreva isso na gramática, ou restrinja o parser.

## 4. Provar que o teste testa

Quebre o código de propósito (troque a ordem de duas alternativas, apague uma palavra obrigatória) e confirme que algum teste falha. Se nenhum falha, falta teste. Desfaça a quebra antes de seguir.

## 5. Revisar antes de pedir revisão

- Releia o diff inteiro procurando o que cortar: comentário que repete o código, linha que faz três coisas, nome que precisa de explicação.
- Documentação e checklists do `CLAUDE.md` batem com o código depois da mudança, inclusive nas seções que a mudança não tocou diretamente.
- Rode `/revisar-pr` no próprio PR e corrija o que ela apontar antes de chamar outra pessoa.
