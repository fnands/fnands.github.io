---
layout: post
title: Parameters in Mojo
categories: [mojo]
excerpt: The 0.4.0 update of Mojo and a look at the novel way Mojo handles parameters when compared to Python. 
---

As Mojo is an extremely new language I want to keep track of the development, and try to learn the language as it evolves.  
I had a first look at version 0.2.1 of the language in a [blog post](https://fnands.com/mojo-advent-of-code/) a few weeks back,
and while on vacation I decided I should probably try and write a blog post every time the Modular team releases a new Mojo update (at least every minor update, not patches).  

To my surprise, in the two weeks I was offline the Modular team managed to do two minor releases, so I'll jump straight to [version 0.4.0](https://docs.modular.com/mojo/changelog.html#v0.4.0-2023-10-05).

## Quick overview

One of the issues I ran into in my last post was due to the fact that Mojo had no native file handling, and I had to invoke Python just to open a simple file. But this has been fixed now, and Mojo now has a very Pythonic way of opening files: 


```python
with open("example.txt", "r") as f:
    print(f.read())
```

    This file
    has two lines


Scanning the changelog, version 0.3.0 seems to bring changes mostly related to supporting keyword arguments, while 0.4.0 seems to mostly be related to how parameters are handled, e.g. adding default parameters. 

This brings up an interesting point:
What exactly are parameters in Mojo?  

## Parameters in Mojo

When searching for the definition of parameters vs. arguments in Python, I get: 
> A parameter is the variable listed inside the parentheses in the function definition.   
An argument is the value that are sent to the function when it is called.

I.e. in Python it is the difference between the name in the function/method definition, vs. the actual data passed.  
To be honest, I have never heard anyone really making this distinction.   

In Mojo however takes a different route here and makes a stronger distinction between parameter and argument, as the following lines from the Mojo documentation shows:  

> Python developers use the words “arguments” and “parameters” fairly interchangeably for “things that are passed into functions.” We decided to reclaim “parameter” and “parameter expression” to represent a compile-time value in Mojo, and continue to use “argument” and “expression” to refer to runtime values. This allows us to align around words like “parameterized” and “parametric” for compile-time metaprogramming. 

In Mojo, arguments are denoted by round brackets like in Python, parameter values are denoted by square brackets. 

So now we can define: 


```python
fn foo[parameter: Int](argument: Int) -> Int:
    return parameter + argument
```

and call it as: 


```python
print(foo[10](5))
```

    15


So the obvious question is: *why*?   
Why separate arguments and parameters when they seem to do the same thing? 

The above statement worked because we are calling it with a fixed parameter value that is known at compile time.   
Let's try and pass a variable instead: 


```python
for i in range(5):
    print(foo[i](5))
```

    error: [0;1;31m[1mExpression [66]:2:15: [0m[1mcannot use a dynamic value in call parameter
    [0m    print(foo[i](5))
    [0;1;32m              ^
    [0m[0m
    expression failed to parse (no further compiler diagnostics)

We get an error.   
Parameter values must be known at compile time, while argument values can be passed at runtime.   
So passing the variable to the argument will work: 


```python
for i in range(5):
    print(foo[10](i))
```

    10
    11
    12
    13
    14


This is another tool one can use in Mojo for optimization: in Python, all arguments are evaluated at runtime, while Mojo adds the option of adding values that are known at compile time as parameters.   

This might be useful in cases where you have some generic version of a function that you might use several versions of.  

As an example, let's write a sliding window summation function that can take different window sizes as parameters:    


```python
from random import rand
from tensor import Tensor, TensorSpec, TensorShape

fn sliding_sum[window_size: Int](data: Tensor[DType.float32]) -> Tensor[DType.float32]:
    
    let contracted_size: Int = data.shape()[0] - window_size

    let out_spec = TensorSpec(DType.float32, contracted_size)
    var out_tensor = Tensor[DType.float32](out_spec)

    for i in range(contracted_size):
        out_tensor[i] = 0
        for j in range(window_size):
            out_tensor[i] += data[i + j]

    return out_tensor
```

The above function takes a window size as a parameter, and a tensor as an argument.   
The function will iterate over the tensor, and add all values in a sliding window of size `window_size`.

As is often the case when creating a convolutional neural network, the size of the kernel is known at compile time, but the data is unknown, allowing the compiler to optimize parts of the operation that are known ahead of time. This means we can define a generic version of the function once, and then still have compiled version of the specific functions we want.    

Let's define a function that calls two versions of the summation: 


```python
fn sum_my_tensor(data: Tensor[DType.float32]) -> Tensor[DType.float32]:

    let summed_by_3 = sliding_sum[3](data)
    let summed_by_5 = sliding_sum[5](summed_by_3)

    return summed_by_5
```

And let's test it:


```python
let random_tensor = rand[DType.float32](10)
print(sum_my_tensor(random_tensor).shape()[0])

```

    2


I haven't yet found an elegant way to print tensors in Mojo. In Python/Pytorch, you can just call `print(tensor)` to see all the values in a tensor. In Mojo this results in an error.  


```python
for i in range(random_tensor.shape()[0]):
    print(random_tensor[i])
```

    0.014950568787753582
    0.64297890663146973
    0.91784769296646118
    0.97008669376373291
    0.84397536516189575
    0.45575159788131714
    0.022083699703216553
    0.70694994926452637
    0.43663844466209412
    0.75171011686325073



```python
summed_by_3 = sliding_sum[3](random_tensor)
for i in range(summed_by_3.shape()[0]):
    print(summed_by_3[i])
```

    1.5757771730422974
    2.5309133529663086
    2.7319097518920898
    2.2698137760162354
    1.3218107223510742
    1.1847852468490601
    1.1656720638275146



```python
summed_by_5 = sliding_sum[5](summed_by_3)
for i in range(summed_by_5.shape()[0]):
    print(summed_by_5[i])
```

    10.430224418640137
    10.03923225402832


## Conclusions

I read a [tweet by Mark Tenenholtz recently](https://x.com/marktenenholtz/status/1716496642323423439) that rang true: 

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Writing a lot of Mojo code and it feels like writing C on hard mode.<br><br>No dict-like structures, file IO is super rudimentary, docs are very sparse, etc.<br><br>It’s actually very fulfilling, though.</p>&mdash; Mark Tenenholtz (@marktenenholtz) <a href="https://twitter.com/marktenenholtz/status/1716496642323423439?ref_src=twsrc%5Etfw">October 23, 2023</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

As pointed out in the replies, even asking ChatGPT doesn't get you very far as the language was released after the current training cut-off date (coupled with the fact that there is no corpus of StackOverflow posts to train on anyway). 


