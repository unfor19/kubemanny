import { greet_normal } from './controller';
import { greet_promise } from './controller';
import { greet_async } from './controller';

function greet_normal_main(event: any) {
    return greet_normal(event.data.name);
}

function greet_promise_main(event: any) {
    return greet_promise(event.data.name);
}

async function greet_async_main(event: any) {
    return await greet_async(event.data.name);
}

module.exports = {
    greet_normal: greet_normal_main,
    greet_promise: greet_promise_main,
    greet_async: greet_async_main,
};
