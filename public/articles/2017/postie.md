```python
from collections import deque

class Postie:
    def __init__(self):
        self.__identifiers = dict()

    def run(self):
        "Run the calculator"
        self.__display_intro()

        while True:
            line = input('> ')
            try:
                ans = self.__process_line(line)
                print(ans)
            except ValueError as e:
                print(e)

    def __process_line(self, line):
        "Process a line inputted by the user"
        calc_stack = deque()
        token_queue = deque(line)

        while token_queue:
            token = token_queue.popleft()

            if token == 'q':
                exit()

            elif token in (' ', '\n'):
                continue

            elif token in ('(', ')'):
                raise ValueError('Error: Parentheses are not supported by Postie')

            elif token == '=':
                if len(calc_stack) < 2:
                    raise ValueError(f'Error: Not enough arguments for "{token}"')
                if len(calc_stack) > 2:
                    raise ValueError(f'Error: Assigment must be the last operation')

                first = calc_stack.pop()
                second = calc_stack.pop()

                if self.__is_identifier(second):
                    self.__identifiers[second] = first
                    return f'{second} = {first}'
                else:
                    raise ValueError(f'Error: Cannot assign {second} to {first}')

            elif token in ['+', '-', '*', '/']:
                if len(calc_stack) < 2:
                    raise ValueError(f'Error: Not enough arguments for "{token}"')

                first = self.__get_value(calc_stack.pop())
                second = self.__get_value(calc_stack.pop())
                value = self.__apply(first, second, token)

                calc_stack.append(value)

            elif self.__is_numeral(token):
                number_literal = token

                while token_queue and token_queue[0] not in (' ', '\n'):
                    token = token_queue.popleft()
                    if self.__is_numeral(token):
                        number_literal += token
                    elif self.__is_alpha(token):
                        raise ValueError('Error: Identifiers must not begin with numbers')
                    else:
                        raise ValueError('Error: Bad symbol in numeric literal')

                calc_stack.append(number_literal)

            elif self.__is_alpha(token):
                identifier = token

                while token_queue and token_queue[0] not in (' ', '\n'):
                    token = token_queue.popleft()
                    if self.__is_alphanumeric(token):
                        identifier += token
                    else:
                        raise ValueError('Error: Bad symbol in identifier')

                calc_stack.append(identifier)

        if len(calc_stack) == 1:
            return self.__get_value(calc_stack.pop())
        else:
            raise ValueError(f'Error: Too many arguments')

    def __get_value(self, symbol):
        if self.__is_identifier(symbol):
            if symbol in self.__identifiers:
                return self.__get_value(self.__identifiers[symbol])
            else:
                raise ValueError(f'Error: Unknown identifier {symbol}')

        if self.__is_number(symbol):
            return int(symbol)

    def __apply(self, first, second, operator):
        if operator == '+':
            return first + second
        elif operator == '-':
            return first - second
        elif operator == '*':
            return first * second
        elif operator == '/':
            return first / second
        else:
            raise ValueError(f'Error: Unknown operator {operator}')

    def __is_alpha(self, token):
        return token in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

    def __is_numeral(self, token):
        return token in '1234567890'

    def __is_alphanumeric(self, token):
        return self.__is_numeral(token) or self.__is_alpha(token)

    def __is_identifier(self, symbol):
        return (
            type(symbol) == str and
            self.__is_alpha(symbol[0]) and 
            all(self.__is_alphanumeric(token) for token in symbol)
        )

    def __is_number(self, symbol):
        return all(self.__is_numeral(token) for token in symbol)

    def __display_intro(self):
        print('Postie v0.1')
        print('A postfix, stack-based calculator written in Python')
        print('Type \'q\' to quit')

if __name__ == '__main__':
    postie = Postie()
    postie.run()
```
